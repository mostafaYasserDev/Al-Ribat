part of '../focus_foreground_service.dart';

Future<void> _clearAllSessionPrefsStatic(SharedPreferences sp) async {
  await sp.remove(FocusForegroundPrefs.endMs);
  await sp.remove(FocusForegroundPrefs.title);
  await sp.remove(FocusForegroundPrefs.plannedMin);
  await sp.remove(FocusForegroundPrefs.startedMs);
  await sp.remove(FocusForegroundPrefs.pausedRemainSec);
  await sp.remove(FocusForegroundPrefs.paused);
}

/// جلسة نشطة: مؤقت يعمل أو موقوفة مؤقتاً أو نهاية مخزّنة.
Future<bool> _hasBlockingSession() async {
  if (FocusForegroundService.isAndroidForegroundSupported &&
      await FlutterForegroundTask.isRunningService) {
    return true;
  }
  final sp = await SharedPreferences.getInstance();
  if (sp.getInt(FocusForegroundPrefs.endMs) != null) return true;
  if (sp.getBool(FocusForegroundPrefs.paused) ?? false) return true;
  if (sp.getInt(FocusForegroundPrefs.pausedRemainSec) != null) return true;
  return false;
}

Future<int?> _pausedRemainSeconds() async {
  final sp = await SharedPreferences.getInstance();
  if (!(sp.getBool(FocusForegroundPrefs.paused) ?? false)) return null;
  final v = sp.getInt(FocusForegroundPrefs.pausedRemainSec);
  return v != null && v > 0 ? v : null;
}

Future<bool> _isPausedAsync() async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool(FocusForegroundPrefs.paused) ?? false;
}

Future<int?> _remainingSecondsIfAny() async {
  final sp = await SharedPreferences.getInstance();
  if (sp.getBool(FocusForegroundPrefs.paused) ?? false) {
    final r = sp.getInt(FocusForegroundPrefs.pausedRemainSec);
    return r != null && r > 0 ? r : null;
  }
  final end = sp.getInt(FocusForegroundPrefs.endMs);
  if (end == null) return null;
  final sec = ((end - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
  return sec > 0 ? sec : null;
}

Future<void> _readSessionMeta(
  void Function(String title, int plannedMin, int startedMs) onData,
) async {
  final sp = await SharedPreferences.getInstance();
  final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
  final planned = sp.getInt(FocusForegroundPrefs.plannedMin) ?? 25;
  final started = sp.getInt(FocusForegroundPrefs.startedMs) ??
      DateTime.now().millisecondsSinceEpoch;
  onData(title, planned, started);
}

Future<void> _clearAllSessionPrefs() async {
  final sp = await SharedPreferences.getInstance();
  await _clearAllSessionPrefsStatic(sp);
}
