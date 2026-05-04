import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مفاتيح تخزين جلسة التركيز.
abstract final class FocusForegroundPrefs {
  static const endMs = 'focus_fg_end_ms';
  static const title = 'focus_fg_title';
  static const plannedMin = 'focus_fg_planned_min';
  static const startedMs = 'focus_fg_started_ms';
  static const pausedRemainSec = 'focus_fg_paused_remain_sec';
  /// يُخزَّن عبر [SharedPreferences.setBool].
  static const paused = 'focus_fg_is_paused';
}

const int _focusServiceId = 887766;

const List<NotificationButton> _kFocusNotificationButtons = [
  NotificationButton(id: 'focus_pause', text: 'إيقاف مؤقت'),
  NotificationButton(id: 'focus_cancel', text: 'إلغاء'),
  NotificationButton(id: 'focus_save', text: 'حفظ'),
];

const List<NotificationButton> _kFocusPausedNotificationButtons = [
  NotificationButton(id: 'focus_resume', text: 'استئناف'),
  NotificationButton(id: 'focus_cancel', text: 'إلغاء'),
  NotificationButton(id: 'focus_save', text: 'حفظ'),
];

bool _pluginInited = false;

Future<void> ensureForegroundTaskPluginInitialized() async {
  if (_pluginInited) return;
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'focus_session_v2',
      channelName: 'جلسات التركيز — الرباط',
      channelDescription:
          'عرض الوقت المتبقي وأزرار الإيقاف المؤقت والاستئناف والإلغاء والحفظ الجزئي.',
      channelImportance: NotificationChannelImportance.DEFAULT,
      priority: NotificationPriority.DEFAULT,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
  _pluginInited = true;
}

@pragma('vm:entry-point')
void focusCountdownTaskCallback() {
  FlutterForegroundTask.setTaskHandler(FocusCountdownTaskHandler());
}

class FocusCountdownTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onNotificationButtonPressed(String id) {
    SharedPreferences.getInstance().then((sp) async {
      final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
      final planned = sp.getInt(FocusForegroundPrefs.plannedMin) ?? 25;
      final started = sp.getInt(FocusForegroundPrefs.startedMs) ?? DateTime.now().millisecondsSinceEpoch;

      if (id == 'focus_pause') {
        final end = sp.getInt(FocusForegroundPrefs.endMs);
        if (end == null) return;
        final remain = ((end - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
        if (remain > 0) {
          await sp.setBool(FocusForegroundPrefs.paused, true);
          await sp.setInt(FocusForegroundPrefs.pausedRemainSec, remain);
          await sp.remove(FocusForegroundPrefs.endMs);
        }
        FlutterForegroundTask.sendDataToMain(<String, dynamic>{'type': 'focus_paused'});
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
        final endMs = DateTime.now().add(Duration(seconds: rem)).millisecondsSinceEpoch;
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
        FlutterForegroundTask.sendDataToMain(<String, dynamic>{'type': 'focus_cancelled'});
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

  @override
  void onRepeatEvent(DateTime timestamp) {
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
        final timeStr = '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
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
      final remainSec = ((end - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
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
      final timeStr = '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
      final line =
          'متبقٍّ $timeStr · إيقاف مؤقت · إلغاء · حفظ (متاح بعد ١٠د)';
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

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

class FocusForegroundService {
  FocusForegroundService._();

  static bool get isAndroidForegroundSupported => !kIsWeb && Platform.isAndroid;

  static Future<void> clearAllSessionPrefsStatic(SharedPreferences sp) async {
    await sp.remove(FocusForegroundPrefs.endMs);
    await sp.remove(FocusForegroundPrefs.title);
    await sp.remove(FocusForegroundPrefs.plannedMin);
    await sp.remove(FocusForegroundPrefs.startedMs);
    await sp.remove(FocusForegroundPrefs.pausedRemainSec);
    await sp.remove(FocusForegroundPrefs.paused);
  }

  static Future<void> requestNotificationIfNeeded() async {
    final p = await FlutterForegroundTask.checkNotificationPermission();
    if (p != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  /// جلسة نشطة: مؤقت يعمل أو موقوفة مؤقتاً أو نهاية مخزّنة.
  static Future<bool> hasBlockingSession() async {
    if (isAndroidForegroundSupported && await FlutterForegroundTask.isRunningService) {
      return true;
    }
    final sp = await SharedPreferences.getInstance();
    if (sp.getInt(FocusForegroundPrefs.endMs) != null) return true;
    if (sp.getBool(FocusForegroundPrefs.paused) ?? false) return true;
    if (sp.getInt(FocusForegroundPrefs.pausedRemainSec) != null) return true;
    return false;
  }

  static Future<int?> pausedRemainSeconds() async {
    final sp = await SharedPreferences.getInstance();
    if (!(sp.getBool(FocusForegroundPrefs.paused) ?? false)) return null;
    final v = sp.getInt(FocusForegroundPrefs.pausedRemainSec);
    return v != null && v > 0 ? v : null;
  }

  static Future<bool> isPausedAsync() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(FocusForegroundPrefs.paused) ?? false;
  }

  static Future<bool> startCountdown({
    required String title,
    required int plannedMinutes,
  }) async {
    if (!isAndroidForegroundSupported) return false;
    if (await hasBlockingSession()) return false;
    await ensureForegroundTaskPluginInitialized();
    await requestNotificationIfNeeded();

    final sp = await SharedPreferences.getInstance();
    final started = DateTime.now();
    final endMs = started.add(Duration(minutes: plannedMinutes)).millisecondsSinceEpoch;
    await sp.setInt(FocusForegroundPrefs.endMs, endMs);
    await sp.setString(FocusForegroundPrefs.title, title);
    await sp.setInt(FocusForegroundPrefs.plannedMin, plannedMinutes);
    await sp.setInt(FocusForegroundPrefs.startedMs, started.millisecondsSinceEpoch);
    await sp.remove(FocusForegroundPrefs.pausedRemainSec);
    await sp.setBool(FocusForegroundPrefs.paused, false);

    return _startForegroundService();
  }

  static Future<bool> _startForegroundService() async {
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

  /// إيقاف مؤقت من التطبيق (نفس منطق الإشعار) — تبقى الخدمة تعمل ويُحدَّث الإشعار.
  static Future<void> pauseFromApp() async {
    if (!isAndroidForegroundSupported) return;
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
    await _updateNotificationForPausedFromMain();
  }

  static Future<void> _updateNotificationForPausedFromMain() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    final sp = await SharedPreferences.getInstance();
    final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
    final rem = sp.getInt(FocusForegroundPrefs.pausedRemainSec) ?? 0;
    if (rem <= 0) return;
    final mm = rem ~/ 60;
    final ss = rem % 60;
    final timeStr = '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    await FlutterForegroundTask.updateService(
      notificationTitle: '⏸ موقوف — $title',
      notificationText:
          'متبقٍّ $timeStr · اضغط «استئناف» للمتابعة أو «إلغاء» أو «حفظ» (بعد ١٠د)',
      notificationButtons: _kFocusPausedNotificationButtons,
    );
  }

  static Future<void> _updateNotificationForRunningFromMain(int remainSec) async {
    if (!await FlutterForegroundTask.isRunningService) return;
    final sp = await SharedPreferences.getInstance();
    final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
    final mm = remainSec ~/ 60;
    final ss = remainSec % 60;
    final timeStr = '${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText:
          'متبقٍّ $timeStr · إيقاف مؤقت · إلغاء · حفظ (متاح بعد ١٠د)',
      notificationButtons: _kFocusNotificationButtons,
    );
  }

  static Future<bool> resumePaused() async {
    if (!isAndroidForegroundSupported) return false;
    final sp = await SharedPreferences.getInstance();
    final sec = sp.getInt(FocusForegroundPrefs.pausedRemainSec);
    if (sec == null || sec <= 0) return false;
    await sp.setBool(FocusForegroundPrefs.paused, false);
    await sp.remove(FocusForegroundPrefs.pausedRemainSec);
    final endMs = DateTime.now().add(Duration(seconds: sec)).millisecondsSinceEpoch;
    await sp.setInt(FocusForegroundPrefs.endMs, endMs);
    await ensureForegroundTaskPluginInitialized();
    await requestNotificationIfNeeded();
    if (await FlutterForegroundTask.isRunningService) {
      await _updateNotificationForRunningFromMain(sec);
      return true;
    }
    return _startForegroundService();
  }

  static Future<void> cancelCompletely() async {
    await FlutterForegroundTask.stopService();
    final sp = await SharedPreferences.getInstance();
    await clearAllSessionPrefsStatic(sp);
  }

  /// حفظ جزئي من التطبيق إذا مرّ ≥ ١٠ دقائق.
  static Future<bool> trySavePartialFromApp() async {
    final sp = await SharedPreferences.getInstance();
    final started = sp.getInt(FocusForegroundPrefs.startedMs);
    if (started == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - started;
    if (elapsed < 600000) return false;
    await FlutterForegroundTask.stopService();
    await clearAllSessionPrefsStatic(sp);
    return true;
  }

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
    final sp = await SharedPreferences.getInstance();
    await sp.remove(FocusForegroundPrefs.endMs);
    await sp.remove(FocusForegroundPrefs.paused);
  }

  static Future<int?> remainingSecondsIfAny() async {
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

  static Future<void> readSessionMeta({
    required void Function(String title, int plannedMin, int startedMs) onData,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final title = sp.getString(FocusForegroundPrefs.title) ?? 'جلسة تركيز';
    final planned = sp.getInt(FocusForegroundPrefs.plannedMin) ?? 25;
    final started = sp.getInt(FocusForegroundPrefs.startedMs) ?? DateTime.now().millisecondsSinceEpoch;
    onData(title, planned, started);
  }

  static Future<void> clearAllSessionPrefs() async {
    final sp = await SharedPreferences.getInstance();
    await clearAllSessionPrefsStatic(sp);
  }
}
