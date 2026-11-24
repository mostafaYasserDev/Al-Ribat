part of '../notification_service.dart';

Future<void> _zonedScheduleWithFallback({
  required NotificationService service,
  required int id,
  required String title,
  required String body,
  required tz.TZDateTime when,
  required NotificationDetails details,
  DateTimeComponents? matchDateTimeComponents,
}) async {
  final primary = await _resolveAndroidScheduleMode(service);
  final modes = <AndroidScheduleMode>[
    primary,
    if (primary != AndroidScheduleMode.inexactAllowWhileIdle)
      AndroidScheduleMode.inexactAllowWhileIdle,
  ];
  Object? lastError;
  for (final mode in modes) {
    try {
      await service._plugin.zonedSchedule(
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
      reportError('NotificationService', e, st);
      lastError = e;
    }
  }
  throw lastError ?? StateError('zonedSchedule failed for id=$id');
}
