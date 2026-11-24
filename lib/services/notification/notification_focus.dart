part of '../notification_service.dart';

Future<void> _showFocusSessionComplete(
  NotificationService service, {
  required String sessionTitle,
  required String body,
}) async {
  if (!NotificationService._notificationsSupported) return;
  await service._ready;
  await service._plugin.show(
    NotificationService._focusCompleteNotificationId,
    'انتهت جلسة التركيز',
    '$sessionTitle\n$body',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationService._focusChannelId,
        'انتهاء جلسة التركيز',
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
    ),
  );
}
