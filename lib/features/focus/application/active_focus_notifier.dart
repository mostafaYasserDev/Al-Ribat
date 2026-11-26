import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/services/focus_foreground_service.dart';
import 'package:al_ribat/services/motivation_quotes.dart';
import '../domain/active_focus_state.dart';
import '../domain/work_session_item.dart';

final activeFocusProvider =
    NotifierProvider<ActiveFocusNotifier, ActiveFocusState?>(
  ActiveFocusNotifier.new,
);

final lastCompletedSessionProvider =
    StateProvider<WorkSessionItem?>((ref) => null);

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
        elapsedSeconds: (planned * 60) - remain,
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
        state = state!.copyWith(
          remainingSeconds: s,
          elapsedSeconds: (state!.plannedMinutes * 60) - s,
          isPaused: false,
        );
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
    int? plannedSeconds,
    FocusSessionMode mode = FocusSessionMode.customTimer,
    String? linkedActivityId,
    String? linkedActivityTitle,
    String? projectName,
  }) async {
    _ticker?.cancel();
    final now = DateTime.now();
    final totalSeconds =
        (plannedSeconds ?? (plannedMinutes * 60)).clamp(1, 86400);
    final effectiveMinutes = (totalSeconds / 60).ceil();

    state = ActiveFocusState(
      title: title.trim().isEmpty ? 'جلسة تركيز' : title.trim(),
      plannedMinutes: effectiveMinutes,
      plannedSeconds: totalSeconds,
      startedAt: now,
      remainingSeconds: totalSeconds,
      elapsedSeconds: 0,
      isPaused: false,
      mode: mode,
      linkedActivityId: linkedActivityId,
      linkedActivityTitle: linkedActivityTitle,
      projectName: projectName,
    );

    if (FocusForegroundService.isAndroidForegroundSupported &&
        mode != FocusSessionMode.openStopwatch) {
      await FocusForegroundService.startCountdown(
        title: state!.title,
        plannedMinutes: effectiveMinutes,
      );
    }

    _startInternalTicker();
  }

  Future<void> startUntilPrayer({
    required String title,
    required DateTime nextPrayerTime,
    String? linkedActivityId,
    String? linkedActivityTitle,
    String? projectName,
  }) async {
    final now = DateTime.now();
    var diffSeconds = nextPrayerTime.difference(now).inSeconds;
    if (diffSeconds <= 60) {
      diffSeconds = 300; // 5 min fallback
    }
    final plannedMin = (diffSeconds / 60).ceil();

    await startSession(
      title: title.isEmpty ? 'الرباط حتى الأذان' : title,
      plannedMinutes: plannedMin,
      plannedSeconds: diffSeconds,
      mode: FocusSessionMode.untilPrayer,
      linkedActivityId: linkedActivityId,
      linkedActivityTitle: linkedActivityTitle,
      projectName: projectName,
    );
  }

  Future<void> startPomodoro({
    required String title,
    int workMinutes = 25,
    String? linkedActivityId,
    String? linkedActivityTitle,
    String? projectName,
  }) async {
    await startSession(
      title: title.isEmpty ? 'بومودورو تركيز' : title,
      plannedMinutes: workMinutes,
      mode: FocusSessionMode.pomodoro,
      linkedActivityId: linkedActivityId,
      linkedActivityTitle: linkedActivityTitle,
      projectName: projectName,
    );
  }

  Future<void> startOpenStopwatch({
    required String title,
    String? linkedActivityId,
    String? linkedActivityTitle,
    String? projectName,
  }) async {
    _ticker?.cancel();
    final now = DateTime.now();

    state = ActiveFocusState(
      title: title.trim().isEmpty ? 'تركيز مفتوح' : title.trim(),
      plannedMinutes: 0,
      startedAt: now,
      remainingSeconds: 0,
      elapsedSeconds: 0,
      isPaused: false,
      mode: FocusSessionMode.openStopwatch,
      linkedActivityId: linkedActivityId,
      linkedActivityTitle: linkedActivityTitle,
      projectName: projectName,
    );

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

      if (current.mode == FocusSessionMode.openStopwatch) {
        state = current.copyWith(
          elapsedSeconds: current.elapsedSeconds + 1,
          plannedMinutes: (current.elapsedSeconds + 1) ~/ 60,
        );
        return;
      }

      if (current.remainingSeconds <= 1) {
        if (current.mode == FocusSessionMode.pomodoro && !current.isBreak) {
          // Save the completed work session first, then transition to 5-min break
          final finishedWork = current.copyWith(
            elapsedSeconds: current.elapsedSeconds + 1,
            remainingSeconds: 0,
          );
          _savePomodoroWorkAndStartBreak(finishedWork);
        } else if (current.isBreak) {
          // Break finished; end cleanly without logging break as work
          timer.cancel();
          state = null;
        } else {
          timer.cancel();
          _completeSession(current.title);
        }
      } else {
        state = current.copyWith(
          remainingSeconds: current.remainingSeconds - 1,
          elapsedSeconds: current.elapsedSeconds + 1,
        );
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

  void linkActivity(String id, String title) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      linkedActivityId: id,
      linkedActivityTitle: title,
      clearLinkedProject: true,
    );
  }

  void linkProject(String projectName) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      projectName: projectName,
      clearLinkedActivity: true,
    );
  }

  void clearLinkedActivity() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      clearLinkedActivity: true,
      clearLinkedProject: true,
    );
  }

  Future<void> _savePomodoroWorkAndStartBreak(ActiveFocusState work) async {
    state = work.copyWith(
      title: 'استراحة قصيرة ☕',
      isBreak: true,
      plannedMinutes: 5,
      plannedSeconds: 5 * 60,
      remainingSeconds: 5 * 60,
      elapsedSeconds: 0,
      clearLinkedActivity: true,
    );

    final session = await _saveSessionRecord(
      title: work.title,
      plannedMinutes: work.plannedMinutes,
      startedAt: work.startedAt,
      elapsedSeconds: work.elapsedSeconds,
      completed: true,
      linkedActivityId: work.linkedActivityId,
      linkedActivityTitle: work.linkedActivityTitle,
      mode: work.mode.name,
    );

    ref.read(lastCompletedSessionProvider.notifier).state = session;
    try {
      await ref.read(notificationServiceProvider).showFocusSessionComplete(
            sessionTitle: work.title,
            body: 'انتهى وقت التركيز! خذ استراحة 5 دقائق.',
          );
    } catch (_) {}
  }

  /// Returns true if [activity] is measured in time units (minutes/hours).
  static bool isTimeMeasuredActivity(ActivityItem activity) {
    if (!activity.isMeasurable) return false;
    final unit = (activity.goalUnit ?? '').trim().toLowerCase();
    return unit.isEmpty ||
        unit.contains('دقيق') ||
        unit.contains('دق') ||
        unit.contains('min') ||
        unit == 'د' ||
        unit.contains('ساع') ||
        unit.contains('hour') ||
        unit == 'h' ||
        unit == 'س';
  }

  Future<void> _applyProgressToActivity(
    ActivityItem activity, {
    required int elapsedSeconds,
    required DateTime referenceDate,
  }) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(referenceDate);

    if (!activity.isMeasurable) {
      final isDone = activity.repetition == ActivityRepetition.once
          ? activity.historyDates.isNotEmpty
          : activity.isDoneOn(todayStr);
      if (!isDone) {
        await ref
            .read(activitiesProvider.notifier)
            .toggleDone(activity, todayStr);
      }
      return;
    }

    if (!isTimeMeasuredActivity(activity)) {
      // Non-time units (e.g. pages, parts) should not be corrupted with minutes.
      return;
    }

    final unit = (activity.goalUnit ?? '').trim().toLowerCase();
    final isHours = unit.contains('ساع') ||
        unit.contains('hour') ||
        unit == 'h' ||
        unit == 'س';

    final double addedValue;
    if (isHours) {
      addedValue = double.parse(
        (elapsedSeconds / 3600.0).clamp(0.05, 24.0).toStringAsFixed(2),
      );
    } else {
      addedValue = (elapsedSeconds / 60.0).ceilToDouble().clamp(1, 1440);
    }

    await ref
        .read(activitiesProvider.notifier)
        .addProgress(activity, todayStr, addedValue);
  }

  Future<void> linkActivityToCompletedSession(
    WorkSessionItem session,
    ActivityItem activity,
  ) async {
    final actualSeconds =
        session.endedAt.difference(session.startedAt).inSeconds.clamp(1, 86400);
    await _applyProgressToActivity(
      activity,
      elapsedSeconds: actualSeconds,
      referenceDate: session.endedAt,
    );

    final updated = session.copyWith(linkedActivityTitle: activity.title);
    await ref.read(workSessionsProvider.notifier).updateSession(updated);
  }

  Future<bool> savePartial() async {
    final current = state;
    if (current == null) return false;

    _ticker?.cancel();
    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.cancelCompletely();
    }

    // If user stops during a Pomodoro break, don't log the break as work.
    if (current.isBreak) {
      state = null;
      return true;
    }

    final session = await _saveSessionRecord(
      title: current.title,
      plannedMinutes: current.plannedMinutes,
      startedAt: current.startedAt,
      elapsedSeconds: current.elapsedSeconds,
      completed: false,
      linkedActivityId: current.linkedActivityId,
      linkedActivityTitle: current.linkedActivityTitle,
      mode: current.mode.name,
    );

    state = null;
    ref.read(lastCompletedSessionProvider.notifier).state = session;
    return true;
  }

  Future<void> _completeSession(String titleHint) async {
    final current = state;
    final title = current?.title ?? titleHint;
    final planned = current?.plannedMinutes ?? 25;
    final started = current?.startedAt ?? DateTime.now();
    final elapsedSec = current?.elapsedSeconds ?? (planned * 60);
    final linkedActId = current?.linkedActivityId;
    final linkedActTitle = current?.linkedActivityTitle;
    final modeName = current?.mode.name ?? FocusSessionMode.customTimer.name;

    _ticker?.cancel();
    if (FocusForegroundService.isAndroidForegroundSupported) {
      await FocusForegroundService.clearAllSessionPrefs();
      await FlutterForegroundTask.stopService();
    }

    state = null;

    final session = await _saveSessionRecord(
      title: title,
      plannedMinutes: planned,
      startedAt: started,
      elapsedSeconds: elapsedSec,
      completed: true,
      linkedActivityId: linkedActId,
      linkedActivityTitle: linkedActTitle,
      mode: modeName,
    );

    ref.read(lastCompletedSessionProvider.notifier).state = session;

    final quote = MotivationQuotes.randomLine();
    try {
      await ref.read(notificationServiceProvider).showFocusSessionComplete(
            sessionTitle: title,
            body: quote,
          );
    } catch (_) {}
  }

  Future<WorkSessionItem> _saveSessionRecord({
    required String title,
    required int plannedMinutes,
    required DateTime startedAt,
    int? elapsedSeconds,
    required bool completed,
    String? linkedActivityId,
    String? linkedActivityTitle,
    String? mode,
  }) async {
    final now = DateTime.now();
    final actualSec = elapsedSeconds ?? now.difference(startedAt).inSeconds;
    final ended =
        actualSec > 0 ? startedAt.add(Duration(seconds: actualSec)) : now;

    final session = WorkSessionItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: title,
      plannedMinutes: plannedMinutes,
      startedAt: startedAt,
      endedAt: ended,
      completed: completed,
      linkedActivityTitle: linkedActivityTitle,
      sessionMode: mode,
    );
    await ref.read(workSessionsProvider.notifier).addSession(session);

    if (linkedActivityId != null) {
      try {
        final acts = ref.read(activitiesProvider).valueOrNull ?? [];
        final act = acts.where((a) => a.id == linkedActivityId).firstOrNull;
        if (act != null) {
          await _applyProgressToActivity(
            act,
            elapsedSeconds: actualSec.clamp(1, 86400),
            referenceDate: ended,
          );
        }
      } catch (_) {}
    }

    return session;
  }
}
