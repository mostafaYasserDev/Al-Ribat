part of '../notification_service.dart';

Future<void> _scheduleActivityNotifications(
  NotificationService service,
  List<ActivityItem> activities,
  AppSettings settings,
) async {
  if (!NotificationService._notificationsSupported) return;
  await service._ready;
  await _cancelPendingWhere(service, (id) => id >= 2000 && id < 9900);

  if (!settings.notificationsEnabled) {
    return;
  }
  await _ensureNotificationPermission(service);

  var nid = 2000;
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  for (final act in activities) {
    if (!act.notificationsEnabled ||
        act.reminderHour == null ||
        act.reminderMinute == null) {
      continue;
    }

    final quote = MotivationQuotes.pickFor(act.id);
    final bodyText =
        '${act.description?.trim().isNotEmpty == true ? '${act.description} — ' : ''}$quote';

    const activityDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationService._activityChannelId,
        'تذكيرات الأنشطة والعادات',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    if (act.repetition == ActivityRepetition.weekly) {
      nid = await _scheduleWeeklyActivity(
        service,
        act,
        nid,
        bodyText,
        activityDetails,
      );
    } else if (act.repetition == ActivityRepetition.daily) {
      nid = await _scheduleDailyActivity(
        service,
        act,
        nid,
        bodyText,
        activityDetails,
        todayStr,
      );
    } else if (act.repetition == ActivityRepetition.once) {
      nid = await _scheduleOnceActivity(
        service,
        act,
        nid,
        bodyText,
        activityDetails,
        todayStr,
      );
    } else {
      nid = await _scheduleMonthlyActivity(
        service,
        act,
        nid,
        bodyText,
        activityDetails,
      );
    }
  }
}
