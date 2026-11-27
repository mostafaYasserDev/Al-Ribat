import 'package:al_ribat/core/constants/prayer_phase.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/domain/entities/app_settings.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:al_ribat/services/calendar/ics_export_service.dart';
import 'package:al_ribat/services/google/google_drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GoogleDriveBackupService parses Drive file list and multipart body',
      () {
    final meta = GoogleDriveBackupService.parseDriveFileList(
      '{"files":[{"id":"file_123","name":"al_ribat_backup.json","modifiedTime":"2026-11-27T00:00:00Z","size":"2048"}]}',
    );
    expect(meta, isNotNull);
    expect(meta!.id, 'file_123');
    expect(meta.sizeBytes, 2048);

    expect(
      GoogleDriveBackupService.parseDriveFileList('{"files":[]}'),
      isNull,
    );

    final bytes = GoogleDriveBackupService.buildMultipartBody(
      boundary: 'b123',
      fileName: 'al_ribat_backup.json',
      jsonContent: '{"version":2}',
    );
    final bodyStr = String.fromCharCodes(bytes);
    expect(bodyStr, contains('appDataFolder'));
    expect(bodyStr, contains('{"version":2}'));
  });

  test(
      'IcsExportService generates valid RFC 5545 VCALENDAR with prayers & tasks',
      () {
    final day = DateTime(2026, 11, 27);
    final schedule = PrayerSchedule(
      today: [
        PrayerTime(
          phase: PrayerPhase.fajr,
          time: DateTime(2026, 11, 27, 5, 0),
        ),
        PrayerTime(
          phase: PrayerPhase.dhuhr,
          time: DateTime(2026, 11, 27, 12, 0),
        ),
      ],
      tomorrowFajr: PrayerTime(
        phase: PrayerPhase.fajr,
        time: DateTime(2026, 11, 28, 5, 1),
      ),
      todaySunrise: DateTime(2026, 11, 27, 6, 25),
    );
    final activities = [
      ActivityItem(
        id: 'a1',
        title: 'مراجعة القرآن, جزء عم',
        createdAt: day,
        type: ActivityType.afterPrayer,
        linkedPrayer: PrayerPhase.fajr,
      ),
      ActivityItem(
        id: 'a2',
        title: 'نشاط بدون وقت',
        createdAt: day,
      ),
    ];

    final events = IcsExportService.buildEventsForSchedule(
      schedule: schedule,
      activities: activities,
      settings: AppSettings.defaults,
      date: day,
    );
    expect(events.length, 3);
    expect(events[2].start, DateTime(2026, 11, 27, 5, 20));

    final ics = IcsExportService.buildIcsContent(events);
    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('SUMMARY:صلاة الفجر'));
    expect(ics, contains(r'SUMMARY:مراجعة القرآن\, جزء عم'));
    expect(ics, contains('END:VCALENDAR'));
  });
}
