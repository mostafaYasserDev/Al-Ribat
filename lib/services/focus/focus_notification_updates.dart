part of '../focus_foreground_service.dart';

Future<void> _updatePausedNotificationFromMain() async {
  if (!await FlutterForegroundTask.isRunningService) return;
  final sp = await SharedPreferences.getInstance();
  final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
  final rem = sp.getInt(FocusForegroundPrefs.pausedRemainSec) ?? 0;
  if (rem <= 0) return;
  final mm = rem ~/ 60;
  final ss = rem % 60;
  final timeStr =
      '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  await FlutterForegroundTask.updateService(
    notificationTitle: '⏸ موقوف — $title',
    notificationText:
        'متبقٍّ $timeStr · اضغط «استئناف» للمتابعة أو «إلغاء» أو «حفظ» (بعد ١٠د)',
    notificationButtons: _kFocusPausedNotificationButtons,
  );
}

Future<void> _updateRunningNotificationFromMain(int remainSec) async {
  if (!await FlutterForegroundTask.isRunningService) return;
  final sp = await SharedPreferences.getInstance();
  final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
  final mm = remainSec ~/ 60;
  final ss = remainSec % 60;
  final timeStr =
      '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  await FlutterForegroundTask.updateService(
    notificationTitle: title,
    notificationText:
        'متبقٍّ $timeStr · إيقاف مؤقت · إلغاء · حفظ (متاح بعد ١٠د)',
    notificationButtons: _kFocusNotificationButtons,
  );
}
