part of '../focus_foreground_service.dart';

void _handleFocusButtonPress(String id) {
  SharedPreferences.getInstance().then((sp) async {
    final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
    final planned = sp.getInt(FocusForegroundPrefs.plannedMin) ?? 25;
    final started = sp.getInt(FocusForegroundPrefs.startedMs) ??
        DateTime.now().millisecondsSinceEpoch;

    if (id == 'focus_pause') {
      final end = sp.getInt(FocusForegroundPrefs.endMs);
      if (end == null) return;
      final remain =
          ((end - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (remain > 0) {
        await sp.setBool(FocusForegroundPrefs.paused, true);
        await sp.setInt(FocusForegroundPrefs.pausedRemainSec, remain);
        await sp.remove(FocusForegroundPrefs.endMs);
      }
      FlutterForegroundTask.sendDataToMain(
          <String, dynamic>{'type': 'focus_paused'});
      return;
    }

    if (id == 'focus_resume') {
      final rem = sp.getInt(FocusForegroundPrefs.pausedRemainSec) ?? 0;
      if (rem <= 0) {
        await sp.setBool(FocusForegroundPrefs.paused, false);
        return;
      }
      await sp.setBool(FocusForegroundPrefs.paused, false);
      await sp.remove(FocusForegroundPrefs.pausedRemainSec);
      final endMs =
          DateTime.now().add(Duration(seconds: rem)).millisecondsSinceEpoch;
      await sp.setInt(FocusForegroundPrefs.endMs, endMs);
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': 'focus_resumed',
        'remainSec': rem,
      });
      return;
    }

    if (id == 'focus_cancel') {
      await FocusForegroundService.clearAllSessionPrefsStatic(sp);
      await FlutterForegroundTask.stopService();
      FlutterForegroundTask.sendDataToMain(
          <String, dynamic>{'type': 'focus_cancelled'});
      return;
    }

    if (id == 'focus_save') {
      final elapsed = DateTime.now().millisecondsSinceEpoch - started;
      if (elapsed < 600000) {
        FlutterForegroundTask.sendDataToMain(<String, dynamic>{
          'type': 'focus_save_too_short',
        });
        return;
      }
      await FocusForegroundService.clearAllSessionPrefsStatic(sp);
      await FlutterForegroundTask.stopService();
      FlutterForegroundTask.sendDataToMain(<String, dynamic>{
        'type': 'focus_save_partial',
        'title': title,
        'plannedMin': planned,
        'startedMs': started,
      });
    }
  });
}
