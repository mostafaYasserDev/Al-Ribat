part of '../focus_foreground_service.dart';

/// إيقاف مؤقت من التطبيق (نفس منطق الإشعار) — تبقى الخدمة تعمل ويُحدَّث الإشعار.
Future<void> _pauseFromApp() async {
  if (!FocusForegroundService.isAndroidForegroundSupported) return;
  final sp = await SharedPreferences.getInstance();
  final end = sp.getInt(FocusForegroundPrefs.endMs);
  if (end == null) return;
  final remain = ((end - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
  if (remain > 0) {
    await sp.setBool(FocusForegroundPrefs.paused, true);
    await sp.setInt(FocusForegroundPrefs.pausedRemainSec, remain);
    await sp.remove(FocusForegroundPrefs.endMs);
  }
  await ensureForegroundTaskPluginInitialized();
  await FocusForegroundService._updateNotificationForPausedFromMain();
}

Future<bool> _resumePaused() async {
  if (!FocusForegroundService.isAndroidForegroundSupported) return false;
  final sp = await SharedPreferences.getInstance();
  final sec = sp.getInt(FocusForegroundPrefs.pausedRemainSec);
  if (sec == null || sec <= 0) return false;
  await sp.setBool(FocusForegroundPrefs.paused, false);
  await sp.remove(FocusForegroundPrefs.pausedRemainSec);
  final endMs =
      DateTime.now().add(Duration(seconds: sec)).millisecondsSinceEpoch;
  await sp.setInt(FocusForegroundPrefs.endMs, endMs);
  await ensureForegroundTaskPluginInitialized();
  await _requestNotificationIfNeeded();
  if (await FlutterForegroundTask.isRunningService) {
    await FocusForegroundService._updateNotificationForRunningFromMain(sec);
    return true;
  }
  return FocusForegroundService._startForegroundService();
}
