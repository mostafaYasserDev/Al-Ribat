part of '../focus_foreground_service.dart';

Future<bool> _startCountdown(String title, int plannedMinutes) async {
  if (!FocusForegroundService.isAndroidForegroundSupported) return false;
  if (await FocusForegroundService.hasBlockingSession()) return false;
  await ensureForegroundTaskPluginInitialized();
  await _requestNotificationIfNeeded();

  final sp = await SharedPreferences.getInstance();
  final started = DateTime.now();
  final endMs =
      started.add(Duration(minutes: plannedMinutes)).millisecondsSinceEpoch;
  await sp.setInt(FocusForegroundPrefs.endMs, endMs);
  await sp.setString(FocusForegroundPrefs.title, title);
  await sp.setInt(FocusForegroundPrefs.plannedMin, plannedMinutes);
  await sp.setInt(
      FocusForegroundPrefs.startedMs, started.millisecondsSinceEpoch);
  await sp.remove(FocusForegroundPrefs.pausedRemainSec);
  await sp.setBool(FocusForegroundPrefs.paused, false);

  return FocusForegroundService._startForegroundService();
}

Future<bool> _startForegroundServiceImpl() async {
  final sp = await SharedPreferences.getInstance();
  final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
  if (await FlutterForegroundTask.isRunningService) {
    await FlutterForegroundTask.stopService();
  }
  final result = await FlutterForegroundTask.startService(
    serviceId: _focusServiceId,
    notificationTitle: title,
    notificationText: '…',
    notificationIcon: null,
    notificationButtons: _kFocusNotificationButtons,
    callback: focusCountdownTaskCallback,
  );
  return switch (result) {
    ServiceRequestSuccess() => true,
    ServiceRequestFailure() => false,
  };
}
