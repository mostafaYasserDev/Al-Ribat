part of '../notification_service.dart';

Future<void> _initializeNotifications(NotificationService service) async {
  if (!NotificationService._notificationsSupported) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const darwin = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const settings = InitializationSettings(
    android: android,
    iOS: darwin,
    macOS: darwin,
  );
  await service._plugin.initialize(settings);

  if (Platform.isAndroid) {
    final androidPlugin = service._plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationService._activityChannelId,
          'تذكيرات الأنشطة والعادات',
          description: 'تنبيهات لمواعيد أداء المهام والعادات والأنشطة.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationService._prayerChannelId,
          'تنبيهات اقتراب الصلاة',
          description: 'تذكيرات بهدوء قبل دخول وقت الصلاة للاستعداد.',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationService._phaseChannelId,
          'مراحل اليوم وأوقات الصلاة',
          description: 'رسائل تحفيزية بعد الصلاة لتحديد أهداف المرحلة.',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }
}

Future<AndroidScheduleMode> _resolveAndroidScheduleMode(
  NotificationService service,
) async {
  if (!Platform.isAndroid) {
    return AndroidScheduleMode.exactAllowWhileIdle;
  }
  final android = service._plugin.resolvePlatformSpecificImplementation<
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
