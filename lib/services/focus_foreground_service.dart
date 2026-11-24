import 'dart:io';

import 'package:al_ribat/core/errors/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'focus/focus_prefs.dart';
part 'focus/focus_task_handler.dart';
part 'focus/focus_button_handler.dart';
part 'focus/focus_repeat_handler.dart';
part 'focus/focus_session_state.dart';
part 'focus/focus_session_lifecycle.dart';
part 'focus/focus_session_start.dart';
part 'focus/focus_session_pause_resume.dart';
part 'focus/focus_notification_updates.dart';

class FocusForegroundService {
  FocusForegroundService._();

  static bool get isAndroidForegroundSupported => !kIsWeb && Platform.isAndroid;

  static Future<void> clearAllSessionPrefsStatic(SharedPreferences sp) =>
      _clearAllSessionPrefsStatic(sp);

  static Future<void> requestNotificationIfNeeded() =>
      _requestNotificationIfNeeded();

  /// جلسة نشطة: مؤقت يعمل أو موقوفة مؤقتاً أو نهاية مخزّنة.
  static Future<bool> hasBlockingSession() => _hasBlockingSession();

  static Future<int?> pausedRemainSeconds() => _pausedRemainSeconds();

  static Future<bool> isPausedAsync() => _isPausedAsync();

  static Future<bool> startCountdown({
    required String title,
    required int plannedMinutes,
  }) =>
      _startCountdown(title, plannedMinutes);

  static Future<bool> _startForegroundService() =>
      _startForegroundServiceImpl();

  /// إيقاف مؤقت من التطبيق (نفس منطق الإشعار) — تبقى الخدمة تعمل ويُحدَّث الإشعار.
  static Future<void> pauseFromApp() => _pauseFromApp();

  static Future<void> _updateNotificationForPausedFromMain() =>
      _updatePausedNotificationFromMain();

  static Future<void> _updateNotificationForRunningFromMain(int remainSec) =>
      _updateRunningNotificationFromMain(remainSec);

  static Future<bool> resumePaused() => _resumePaused();

  static Future<void> cancelCompletely() => _cancelCompletely();

  /// حفظ جزئي من التطبيق إذا مرّ ≥ ١٠ دقائق.
  static Future<bool> trySavePartialFromApp() => _trySavePartialFromApp();

  static Future<void> stop() => _stop();

  static Future<int?> remainingSecondsIfAny() => _remainingSecondsIfAny();

  static Future<void> readSessionMeta({
    required void Function(String title, int plannedMin, int startedMs) onData,
  }) =>
      _readSessionMeta(onData);

  static Future<void> clearAllSessionPrefs() => _clearAllSessionPrefs();
}
