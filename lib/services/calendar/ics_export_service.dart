import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_time.dart';

class CalendarEventSpec {
  const CalendarEventSpec({
    required this.uid,
    required this.summary,
    required this.description,
    required this.start,
    required this.end,
  });

  final String uid;
  final String summary;
  final String description;
  final DateTime start;
  final DateTime end;
}

/// Generates standard RFC 5545 `.ics` calendar files for prayer times and
/// scheduled activities (works with Apple Calendar, Google Calendar, Outlook).
abstract final class IcsExportService {
  static List<CalendarEventSpec> buildEventsForSchedule({
    required PrayerSchedule schedule,
    required List<ActivityItem> activities,
    required AppSettings settings,
    DateTime? date,
  }) {
    final targetDate = date ?? DateTime.now();
    final events = <CalendarEventSpec>[];
    final slotDuration = Duration(minutes: settings.prayerSlotDurationMinutes);

    for (final p in schedule.today) {
      events.add(
        CalendarEventSpec(
          uid: 'alribat-prayer-${_dateKey(p.time)}-${p.phase.name}@alribat.app',
          summary: 'صلاة ${p.phase.arabicName}',
          description: 'وقت صلاة ${p.phase.arabicName} — تطبيق الرباط',
          start: p.time,
          end: p.time.add(slotDuration),
        ),
      );
    }

    for (final act in activities) {
      final start =
          _resolveActivityTime(act, schedule.today, targetDate, settings);
      if (start == null) continue;
      events.add(
        CalendarEventSpec(
          uid: 'alribat-act-${_dateKey(targetDate)}-${act.id}@alribat.app',
          summary: act.title,
          description: act.description ?? 'نشاط مجدول — تطبيق الرباط',
          start: start,
          end: start.add(const Duration(minutes: 30)),
        ),
      );
    }

    return events;
  }

  static DateTime? _resolveActivityTime(
    ActivityItem act,
    List<PrayerTime> prayers,
    DateTime date,
    AppSettings settings,
  ) {
    if (act.reminderHour != null && act.reminderMinute != null) {
      return DateTime(
        date.year,
        date.month,
        date.day,
        act.reminderHour!,
        act.reminderMinute!,
      );
    }
    if (act.linkedPrayer != null) {
      for (final p in prayers) {
        if (p.phase == act.linkedPrayer) {
          if (act.type == ActivityType.beforePrayer) {
            return p.time
                .subtract(Duration(minutes: settings.focusLeadMinutes));
          }
          if (act.type == ActivityType.afterPrayer) {
            return p.time
                .add(Duration(minutes: settings.prayerSlotDurationMinutes));
          }
          return p.time;
        }
      }
    }
    return null;
  }

  static String buildIcsContent(List<CalendarEventSpec> events) {
    final buf = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//Al-Ribat//Prayer Productivity//AR')
      ..writeln('CALSCALE:GREGORIAN')
      ..writeln('METHOD:PUBLISH');

    final stamp = _formatUtc(DateTime.now().toUtc());
    for (final e in events) {
      buf
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${e.uid}')
        ..writeln('DTSTAMP:$stamp')
        ..writeln('DTSTART:${_formatUtc(e.start.toUtc())}')
        ..writeln('DTEND:${_formatUtc(e.end.toUtc())}')
        ..writeln('SUMMARY:${_escape(e.summary)}')
        ..writeln('DESCRIPTION:${_escape(e.description)}')
        ..writeln('END:VEVENT');
    }
    buf.writeln('END:VCALENDAR');
    return buf.toString();
  }

  static Future<bool> exportInteractive({
    required PrayerSchedule schedule,
    required List<ActivityItem> activities,
    required AppSettings settings,
  }) async {
    final events = buildEventsForSchedule(
      schedule: schedule,
      activities: activities,
      settings: settings,
    );
    final ics = buildIcsContent(events);
    const fileName = 'al_ribat_schedule.ics';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';
      await File(path).writeAsString(ics, flush: true);
      await Share.shareXFiles([XFile(path)], subject: 'جدول الرباط (.ics)');
      return true;
    }

    final dest = await FilePicker.platform.saveFile(
      dialogTitle: 'تصدير جدول اليوم (.ics)',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['ics'],
    );
    if (dest == null) return false;
    final outPath = dest.toLowerCase().endsWith('.ics') ? dest : '$dest.ics';
    await File(outPath).writeAsString(ics, flush: true);
    return true;
  }

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _formatUtc(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    final ss = utc.second.toString().padLeft(2, '0');
    return '$y$m${d}T$hh$mm${ss}Z';
  }

  static String _escape(String text) => text
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
}
