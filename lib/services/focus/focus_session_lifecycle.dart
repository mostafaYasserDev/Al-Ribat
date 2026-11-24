part of '../focus_foreground_service.dart';

Future<void> _requestNotificationIfNeeded() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  try {
    final p = await FlutterForegroundTask.checkNotificationPermission();
    if (p != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  } catch (e, st) {
    reportError('FocusForegroundService', e, st);
  }
}

Future<void> _cancelCompletely() async {
  await FlutterForegroundTask.stopService();
  final sp = await SharedPreferences.getInstance();
  await _clearAllSessionPrefsStatic(sp);
}

/// حفظ جزئي من التطبيق إذا مرّ ≥ ١٠ دقائق.
Future<bool> _trySavePartialFromApp() async {
  final sp = await SharedPreferences.getInstance();
  final started = sp.getInt(FocusForegroundPrefs.startedMs);
  if (started == null) return false;
  final elapsed = DateTime.now().millisecondsSinceEpoch - started;
  if (elapsed < 600000) return false;
  await FlutterForegroundTask.stopService();
  await _clearAllSessionPrefsStatic(sp);
  return true;
}

Future<void> _stop() async {
  await FlutterForegroundTask.stopService();
  final sp = await SharedPreferences.getInstance();
  await sp.remove(FocusForegroundPrefs.endMs);
  await sp.remove(FocusForegroundPrefs.paused);
}
