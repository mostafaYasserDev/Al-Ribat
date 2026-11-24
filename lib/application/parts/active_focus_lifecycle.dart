part of '../active_focus_provider.dart';

mixin _ActiveFocusLifecycle on _ActiveFocusNotifierBase {
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
}
