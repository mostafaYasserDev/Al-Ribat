part of '../active_focus_provider.dart';

mixin _ActiveFocusCompletion on _ActiveFocusNotifierBase {
  @override
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

  @override
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
