import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Android 13+ notifications and exact-alarm capability where applicable.
class AppPermissions {
  static Future<void> requestNotificationIfNeeded() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.notification.status;
    if (status.isGranted) return;
    await Permission.notification.request();
  }

  static Future<void> requestExactAlarmIfNeeded() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) return;
      await Permission.scheduleExactAlarm.request();
    } catch (_) {}
  }
}
