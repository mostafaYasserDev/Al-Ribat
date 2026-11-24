part of '../focus_foreground_service.dart';

void _handleFocusRepeatEvent(DateTime timestamp) {
  SharedPreferences.getInstance().then((sp) async {
    final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
    final isPaused = sp.getBool(FocusForegroundPrefs.paused) ?? false;

    if (isPaused) {
      final rem = sp.getInt(FocusForegroundPrefs.pausedRemainSec) ?? 0;
      if (rem <= 0) {
        await sp.setBool(FocusForegroundPrefs.paused, false);
        await FlutterForegroundTask.stopService();
        return;
      }
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
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': 'focus_paused_tick',
        'remainSec': rem,
      });
      return;
    }

    final end = sp.getInt(FocusForegroundPrefs.endMs);
    if (end == null) {
      await FlutterForegroundTask.stopService();
      return;
    }
    final remainSec =
        ((end - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    if (remainSec <= 0) {
      await sp.remove(FocusForegroundPrefs.endMs);
      await FlutterForegroundTask.stopService();
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': 'focus_done',
        'title': title,
      });
      return;
    }
    final mm = remainSec ~/ 60;
    final ss = remainSec % 60;
    final timeStr =
        '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    final line = 'متبقٍّ $timeStr · إيقاف مؤقت · إلغاء · حفظ (متاح بعد ١٠د)';
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: line,
      notificationButtons: _kFocusNotificationButtons,
    );
    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'type': 'focus_tick',
      'remainSec': remainSec,
    });
  });
}
