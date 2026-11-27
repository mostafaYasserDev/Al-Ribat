import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/activity_item.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../google/google_account_service.dart';
import 'ics_export_service.dart';

/// Syncs prayer blocks and scheduled activities into a dedicated secondary
/// Google Calendar (`الرباط — أوقات الصلاة`) using incremental OAuth scopes.
abstract final class GoogleCalendarSyncService {
  static const _scope = 'https://www.googleapis.com/auth/calendar';
  static const _calendarTitle = 'الرباط — أوقات الصلاة';
  static const _calendarIdKey = 'google_calendar_id';
  static const _syncMapKey = 'google_calendar_sync_map';

  static Future<String> ensureAlRibatCalendar() async {
    final box =
        Hive.isBoxOpen('meta_box') ? Hive.box<String>('meta_box') : null;
    final cachedId = box?.get(_calendarIdKey);
    if (cachedId != null && cachedId.isNotEmpty) {
      final check = await GoogleAccountService.authorizedRequest(
        method: 'GET',
        uri: Uri.https(
          'www.googleapis.com',
          '/calendar/v3/calendars/${Uri.encodeComponent(cachedId)}',
        ),
        scopes: const [_scope],
      );
      if (check.statusCode >= 200 && check.statusCode < 300) {
        return cachedId;
      }
    }

    // Look for an existing Al-Ribat calendar before creating a new one.
    final listResp = await GoogleAccountService.authorizedRequest(
      method: 'GET',
      uri:
          Uri.https('www.googleapis.com', '/calendar/v3/users/me/calendarList'),
      scopes: const [_scope],
    );
    if (listResp.statusCode >= 200 && listResp.statusCode < 300) {
      final decoded = jsonDecode(listResp.body);
      final items = decoded is Map ? decoded['items'] : null;
      if (items is List) {
        for (final item in items) {
          if (item is Map && item['summary'] == _calendarTitle) {
            final id = item['id']?.toString();
            if (id != null && id.isNotEmpty) {
              await box?.put(_calendarIdKey, id);
              return id;
            }
          }
        }
      }
    }

    final createResp = await GoogleAccountService.authorizedRequest(
      method: 'POST',
      uri: Uri.https('www.googleapis.com', '/calendar/v3/calendars'),
      scopes: const [_scope],
      extraHeaders: const {'Content-Type': 'application/json; charset=utf-8'},
      bodyBytes: utf8.encode(
        jsonEncode({
          'summary': _calendarTitle,
          'description': 'أوقات الصلاة والأنشطة المجدولة من تطبيق الرباط',
          'timeZone': tz.local.name,
        }),
      ),
    );
    if (createResp.statusCode < 200 || createResp.statusCode >= 300) {
      throw Exception(
        'تعذر إنشاء تقويم الرباط في Google (${createResp.statusCode}).',
      );
    }
    final created = jsonDecode(createResp.body) as Map<String, dynamic>;
    final newId = created['id']?.toString() ?? '';
    if (newId.isEmpty) {
      throw Exception('لم يُعد Google معرف التقويم الجديد.');
    }
    await box?.put(_calendarIdKey, newId);
    return newId;
  }

  static Future<({int syncedEvents})> syncTodaySchedule({
    required PrayerSchedule schedule,
    required List<ActivityItem> activities,
    required AppSettings settings,
  }) async {
    final calendarId = await ensureAlRibatCalendar();
    final box =
        Hive.isBoxOpen('meta_box') ? Hive.box<String>('meta_box') : null;
    final syncMap = _loadSyncMap(box);

    final events = IcsExportService.buildEventsForSchedule(
      schedule: schedule,
      activities: activities,
      settings: settings,
    );

    var synced = 0;
    for (final ev in events) {
      final body = jsonEncode({
        'summary': ev.summary,
        'description': ev.description,
        'start': {
          'dateTime': ev.start.toUtc().toIso8601String(),
          'timeZone': tz.local.name,
        },
        'end': {
          'dateTime': ev.end.toUtc().toIso8601String(),
          'timeZone': tz.local.name,
        },
      });

      final existingId = syncMap[ev.uid];
      if (existingId != null && existingId.isNotEmpty) {
        final patch = await GoogleAccountService.authorizedRequest(
          method: 'PUT',
          uri: Uri.https(
            'www.googleapis.com',
            '/calendar/v3/calendars/${Uri.encodeComponent(calendarId)}/events/${Uri.encodeComponent(existingId)}',
          ),
          scopes: const [_scope],
          extraHeaders: const {
            'Content-Type': 'application/json; charset=utf-8'
          },
          bodyBytes: utf8.encode(body),
        );
        if (patch.statusCode >= 200 && patch.statusCode < 300) {
          synced++;
          continue;
        }
      }

      final insert = await GoogleAccountService.authorizedRequest(
        method: 'POST',
        uri: Uri.https(
          'www.googleapis.com',
          '/calendar/v3/calendars/${Uri.encodeComponent(calendarId)}/events',
        ),
        scopes: const [_scope],
        extraHeaders: const {'Content-Type': 'application/json; charset=utf-8'},
        bodyBytes: utf8.encode(body),
      );
      if (insert.statusCode >= 200 && insert.statusCode < 300) {
        final created = jsonDecode(insert.body) as Map<String, dynamic>;
        final eventId = created['id']?.toString();
        if (eventId != null && eventId.isNotEmpty) {
          syncMap[ev.uid] = eventId;
        }
        synced++;
      }
    }

    await box?.put(_syncMapKey, jsonEncode(syncMap));
    return (syncedEvents: synced);
  }

  static Map<String, String> _loadSyncMap(Box<String>? box) {
    final raw = box?.get(_syncMapKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }
}
