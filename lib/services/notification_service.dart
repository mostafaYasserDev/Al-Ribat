import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

import '../core/constants/prayer_phase.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/activity_item.dart';
import '../domain/entities/prayer_time.dart';
import 'motivation_quotes.dart';

class NotificationService {
  static const _activityChannelId = 'activity_reminders_v2';

  NotificationService() {
    _ready = _init();
  }

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final Future<void> _ready;

  Future<void> _init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
      try {
        final granted = await android?.requestExactAlarmsPermission();
        if (granted == true) {
          return AndroidScheduleMode.exactAllowWhileIdle;
        }
      } catch (_) {}
      final req = await Permission.scheduleExactAlarm.request();
      if (req.isGranted) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {}
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  Future<void> _cancelPendingWhere(bool Function(int id) test) async {
    await _ready;
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (test(request.id)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final primary = await _resolveAndroidScheduleMode();
    final modes = <AndroidScheduleMode>[
      primary,
      if (primary != AndroidScheduleMode.inexactAllowWhileIdle)
        AndroidScheduleMode.inexactAllowWhileIdle,
    ];
    Object? lastError;
    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        return;
      } catch (e, st) {
        debugPrint('FLN zonedSchedule id=$id mode=$mode: $e\n$st');
        lastError = e;
      }
    }
    throw lastError ?? StateError('zonedSchedule failed for id=$id');
  }

  Future<void> schedulePrayerNotifications(
    List<PrayerTime> prayers,
    AppSettings settings,
  ) async {
    await _ready;
    if (!settings.notificationsEnabled) {
      await _plugin.cancelAll();
      return;
    }
    await ensureNotificationPermission();

    await _cancelPendingWhere(
      (id) => (id >= 1 && id <= 32) || (id >= 100 && id < 200),
    );

    for (var i = 0; i < prayers.length; i++) {
      final p = prayers[i];
      final scheduled = p.time.subtract(Duration(minutes: settings.focusLeadMinutes));
      final afterPrayerPrompt = p.time.add(Duration(minutes: settings.prayerSlotDurationMinutes));
      if (scheduled.isBefore(DateTime.now()) && afterPrayerPrompt.isBefore(DateTime.now())) {
        continue;
      }

      if (scheduled.isAfter(DateTime.now())) {
        try {
          await _zonedScheduleWithFallback(
            id: i + 1,
            title: 'اقترب وقت ${p.phase.arabicName}',
            body: settings.focusModeEnabled
                ? 'وضع الهدوء مفعل. أنهِ ما لديك واستعد للصلاة.'
                : 'استعد بهدوء للصلاة القادمة',
            when: tz.TZDateTime.from(scheduled, tz.local),
            details: const NotificationDetails(
              android: AndroidNotificationDetails(
                'prayer_reminders',
                'Prayer Reminders',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        } catch (e, st) {
          debugPrint('Prayer lead notification failed: $e\n$st');
        }
      }

      if (afterPrayerPrompt.isAfter(DateTime.now())) {
        try {
          await _zonedScheduleWithFallback(
            id: 100 + i,
            title: 'بدأت مرحلة ${p.phase.arabicName}',
            body: 'ما المهمة أو النشاط الذي تريد إنجازه الآن؟',
            when: tz.TZDateTime.from(afterPrayerPrompt, tz.local),
            details: const NotificationDetails(
              android: AndroidNotificationDetails(
                'phase_prompts',
                'Phase Prompts',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
            ),
          );
        } catch (e, st) {
          debugPrint('Phase prompt notification failed: $e\n$st');
        }
      }
    }
  }

  tz.TZDateTime _nextDartWeekdayOccurrence(int hour, int minute, int dartWeekday) {
    final now = tz.TZDateTime.now(tz.local);
    for (var add = 0; add < 14; add++) {
      final base = now.add(Duration(days: add));
      final t = tz.TZDateTime(tz.local, base.year, base.month, base.day, hour, minute);
      if (t.weekday == dartWeekday && t.isAfter(now)) {
        return t;
      }
    }
    return now.add(const Duration(days: 1));
  }

  Future<void> scheduleActivityNotifications(
    List<ActivityItem> activities,
    AppSettings settings,
  ) async {
    await _ready;
    await _cancelPendingWhere((id) => id >= 2000 && id < 9900);

    if (!settings.notificationsEnabled) {
      return;
    }
    await ensureNotificationPermission();

    var nid = 2000;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (final act in activities) {
      if (!act.notificationsEnabled || act.reminderHour == null || act.reminderMinute == null) {
        continue;
      }
      
      if (act.isDoneOn(todayStr) || act.isSkippedOn(todayStr)) {
        continue;
      }

      final quote = MotivationQuotes.pickFor(act.id);
      final bodyText = '${act.description?.trim().isNotEmpty == true ? '${act.description} — ' : ''}$quote';
      
      if (act.repetition == ActivityRepetition.weekly) {
        for (final wd in act.repeatDays) {
          if (nid >= 9899) break;
          final when = _nextDartWeekdayOccurrence(act.reminderHour!, act.reminderMinute!, wd);
          try {
            await _zonedScheduleWithFallback(
              id: nid,
              title: 'موعد نشاطك: ${act.title}',
              body: bodyText,
              when: when,
              details: const NotificationDetails(
                android: AndroidNotificationDetails(
                  _activityChannelId,
                  'تذكيرات الأنشطة والعادات',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                ),
              ),
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          } catch (e, st) {}
          nid++;
        }
      } else if (act.repetition == ActivityRepetition.daily) {
        final now = tz.TZDateTime.now(tz.local);
        var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, act.reminderHour!, act.reminderMinute!);
        if (!when.isAfter(now)) {
          when = when.add(const Duration(days: 1));
        }
        try {
          await _zonedScheduleWithFallback(
            id: nid,
            title: 'موعد نشاطك: ${act.title}',
            body: bodyText,
            when: when,
            details: const NotificationDetails(
              android: AndroidNotificationDetails(
                _activityChannelId,
                'تذكيرات الأنشطة والعادات',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
              ),
            ),
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e, st) {}
        nid++;
      } else {
        // Once or Monthly (simplified to just next occurrence if it's today)
        final now = tz.TZDateTime.now(tz.local);
        var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, act.reminderHour!, act.reminderMinute!);
        if (when.isAfter(now)) {
          try {
            await _zonedScheduleWithFallback(
              id: nid,
              title: 'موعد نشاطك: ${act.title}',
              body: bodyText,
              when: when,
              details: const NotificationDetails(
                android: AndroidNotificationDetails(
                  _activityChannelId,
                  'تذكيرات الأنشطة والعادات',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                ),
              ),
            );
          } catch (e, st) {}
          nid++;
        }
      }
    }
  }

  static const _focusCompleteNotificationId = 971002;

  Future<void> showFocusSessionComplete({
    required String sessionTitle,
    required String body,
  }) async {
    await _ready;
    await _plugin.show(
      _focusCompleteNotificationId,
      'انتهت جلسة التركيز',
      '$sessionTitle\n$body',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_complete',
          'انتهاء جلسة التركيز',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }
}
