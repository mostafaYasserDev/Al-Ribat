import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/services/focus_foreground_service.dart';
import 'package:al_ribat/services/motivation_quotes.dart';
import '../domain/active_focus_state.dart';
import '../domain/work_session_item.dart';

final activeFocusProvider =
    NotifierProvider<ActiveFocusNotifier, ActiveFocusState?>(
  ActiveFocusNotifier.new,
);

class ActiveFocusNotifier extends Notifier<ActiveFocusState?> {
  Timer? _ticker;

  @override
  ActiveFocusState? build() {
    _checkExistingForegroundSession();
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
    ref.onDispose(() {
      _ticker?.cancel();
      FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    });
    return null;
  }

  Future<void> _checkExistingForegroundSession() async {
    final remain = await FocusForegroundService.remainingSecondsIfAny();
    final isPaused = await FocusForegroundService.isPausedAsync();
    if (remain != null && remain > 0) {
      String title = 'جلسة تركيز';
      int planned = 25;
      int startedMs = DateTime.now().millisecondsSinceEpoch;
      await FocusForegroundService.readSessionMeta(
        onData: (t, p, s) {
          title = t;
          planned = p;
          startedMs = s;
        },
      );

      state = ActiveFocusState(
        title: title,
        plannedMinutes: planned,
        startedAt: DateTime.fromMillisecondsSinceEpoch(startedMs),
        remainingSeconds: remain,
        isPaused: isPaused,
      );

      if (!isPaused) {
        _startInternalTicker();
      }
    }
  }

  void _onForegroundTaskData(Object data) {
    if (data is! Map) return;
    final type = data['type'] as String?;
    if (type == 'focus_tick') {
      final s = data['remainSec'] as int?;
      if (s != null && state != null) {
        state = state!.copyWith(remainingSeconds: s, isPaused: false);
      }
    } else if (type == 'focus_paused_tick') {
      final s = data['remainSec'] as int?;
      if (s != null && state != null) {
        state = state!.copyWith(remainingSeconds: s, isPaused: true);
      }
    } else if (type == 'focus_paused') {
      state = state?.copyWith(isPaused: true);
      _ticker?.cancel();
    } else if (type == 'focus_resumed') {
      final s = data['remainSec'] as int?;
      state = state?.copyWith(
        remainingSeconds: s ?? state?.remainingSeconds,
        isPaused: false,
      );
      _startInternalTicker();
    } else if (type == 'focus_done') {
      final title = data['title'] as String? ?? (state?.title ?? 'جلسة تركيز');
      _completeSession(title);
    } else if (type == 'focus_cancelled') {
      _ticker?.cancel();
      state = null;
    } else if (type == 'focus_save_partial') {
      final title = data['title'] as String? ?? (state?.title ?? 'جلسة تركيز');
      final plannedRaw = data['plannedMin'];
      final planned =
          plannedRaw is int ? plannedRaw : (state?.plannedMinutes ?? 25);
      final startedRaw = data['startedMs'];
      final startedMs = startedRaw is int
          ? startedRaw
          : (state?.startedAt.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch);

      _saveSessionRecord(
        title: title,
        plannedMinutes: planned,
        startedAt: DateTime.fromMillisecondsSinceEpoch(startedMs),
        completed: false,
      );
      _ticker?.cancel();
      state = null;
    }
  }

  Future<void> startSession({
    required String title,
    required int plannedMinutes,
  }) async {
    _ticker?.cancel();
    final now = DateTime.now();
    final totalSeconds = plannedMinutes * 60;

    state = ActiveFocusState(
      title: title.trim().isEmpty ? 'جلسة تركيز' : title.trim(),
      plannedMinutes: plannedMinutes,
      startedAt: now,
      remainingSeconds: totalSeconds,
      isPaused: false,
    );

    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.startCountdown(
        title: state!.title,
        plannedMinutes: plannedMinutes,
      );
    }

    _startInternalTicker();
  }

  void _startInternalTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state;
      if (current == null || current.isPaused) {
        timer.cancel();
        return;
      }

      if (current.remainingSeconds <= 1) {
        timer.cancel();
        _completeSession(current.title);
      } else {
        state =
            current.copyWith(remainingSeconds: current.remainingSeconds - 1);
      }
    });
  }

  Future<void> pauseSession() async {
    _ticker?.cancel();
    if (state != null) {
      state = state!.copyWith(isPaused: true);
    }
    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.pauseFromApp();
    }
  }

  Future<void> resumeSession() async {
    if (state != null) {
      state = state!.copyWith(isPaused: false);
      _startInternalTicker();
    }
    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.resumePaused();
    }
  }

  Future<void> cancelSession() async {
    _ticker?.cancel();
    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.cancelCompletely();
    }
    state = null;
  }

  Future<bool> savePartial() async {
    final current = state;
    if (current == null) return false;

    if (!current.canSavePartial) {
      return false;
    }

    _ticker?.cancel();
    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.cancelCompletely();
    }

    await _saveSessionRecord(
      title: current.title,
      plannedMinutes: current.plannedMinutes,
      startedAt: current.startedAt,
      completed: false,
    );

    state = null;
    return true;
  }

  Future<void> _completeSession(String titleHint) async {
    final current = state;
    final title = current?.title ?? titleHint;
    final planned = current?.plannedMinutes ?? 25;
    final started = current?.startedAt ?? DateTime.now();

    _ticker?.cancel();
    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.clearAllSessionPrefs();
      await FlutterForegroundTask.stopService();
    }

    state = null;

    await _saveSessionRecord(
      title: title,
      plannedMinutes: planned,
      startedAt: started,
      completed: true,
    );

    final quote = MotivationQuotes.randomLine();
    try {
      await ref.read(notificationServiceProvider).showFocusSessionComplete(
            sessionTitle: title,
            body: quote,
          );
    } catch (_) {}
  }

  Future<void> _saveSessionRecord({
    required String title,
    required int plannedMinutes,
    required DateTime startedAt,
    required bool completed,
  }) async {
    final session = WorkSessionItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: title,
      plannedMinutes: plannedMinutes,
      startedAt: startedAt,
      endedAt: DateTime.now(),
      completed: completed,
    );
    await ref.read(workSessionsProvider.notifier).addSession(session);
  }
}
