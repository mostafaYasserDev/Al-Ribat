part of '../notification_service.dart';

Future<void> _ensureNotificationPermission(NotificationService service) async {
  if (!NotificationService._notificationsSupported) return;
  if (Platform.isAndroid) {
    try {
      final android = service._plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (_) {}
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}
  } else if (Platform.isIOS) {
    try {
      final ios = service._plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }
}

Future<void> _cancelPendingWhere(
  NotificationService service,
  bool Function(int id) test,
) async {
  await service._ready;
  final pending = await service._plugin.pendingNotificationRequests();
  for (final request in pending) {
    if (test(request.id)) {
      await service._plugin.cancel(request.id);
    }
  }
}

tz.TZDateTime _nextDartWeekdayOccurrence(
  int hour,
  int minute,
  int dartWeekday,
) {
  final now = tz.TZDateTime.now(tz.local);
  for (var add = 0; add < 14; add++) {
    final base = now.add(Duration(days: add));
    final t = tz.TZDateTime(
      tz.local,
      base.year,
      base.month,
      base.day,
      hour,
      minute,
    );
    if (t.weekday == dartWeekday && t.isAfter(now)) {
      return t;
    }
  }
  return now.add(const Duration(days: 1));
}
