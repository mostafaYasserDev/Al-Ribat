part of '../active_focus_provider.dart';

mixin _ActiveFocusSession on _ActiveFocusNotifierBase {
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

  @override
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
}
