part of '../active_focus_provider.dart';

mixin _ActiveFocusForeground on _ActiveFocusNotifierBase {
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
}
