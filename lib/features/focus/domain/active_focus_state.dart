enum FocusSessionMode {
  untilPrayer,
  pomodoro,
  customTimer,
  openStopwatch;

  String get arabicLabel {
    switch (this) {
      case FocusSessionMode.untilPrayer:
        return 'الرباط حتى الأذان';
      case FocusSessionMode.pomodoro:
        return 'بومودورو ذكي';
      case FocusSessionMode.customTimer:
        return 'مؤقت مخصص';
      case FocusSessionMode.openStopwatch:
        return 'تركيز مفتوح';
    }
  }
}

class ActiveFocusState {
  final String title;
  final int plannedMinutes;
  final int plannedSeconds;
  final DateTime startedAt;
  final int remainingSeconds;
  final int elapsedSeconds;
  final bool isPaused;
  final FocusSessionMode mode;
  final String? linkedActivityId;
  final String? linkedActivityTitle;
  final String? projectName;
  final bool isBreak;
  final int pomodoroCycle;

  /// Any active session can be saved manually when the user chooses to finish.
  bool get canSavePartial => true;

  const ActiveFocusState({
    required this.title,
    required this.plannedMinutes,
    int? plannedSeconds,
    required this.startedAt,
    required this.remainingSeconds,
    this.elapsedSeconds = 0,
    this.isPaused = false,
    this.mode = FocusSessionMode.customTimer,
    this.linkedActivityId,
    this.linkedActivityTitle,
    this.projectName,
    this.isBreak = false,
    this.pomodoroCycle = 1,
  }) : plannedSeconds = plannedSeconds ?? (plannedMinutes * 60);

  ActiveFocusState copyWith({
    String? title,
    int? plannedMinutes,
    int? plannedSeconds,
    DateTime? startedAt,
    int? remainingSeconds,
    int? elapsedSeconds,
    bool? isPaused,
    FocusSessionMode? mode,
    String? linkedActivityId,
    String? linkedActivityTitle,
    bool clearLinkedActivity = false,
    String? projectName,
    bool? isBreak,
    int? pomodoroCycle,
  }) {
    return ActiveFocusState(
      title: title ?? this.title,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      plannedSeconds: plannedSeconds ?? this.plannedSeconds,
      startedAt: startedAt ?? this.startedAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      mode: mode ?? this.mode,
      linkedActivityId: clearLinkedActivity
          ? null
          : (linkedActivityId ?? this.linkedActivityId),
      linkedActivityTitle: clearLinkedActivity
          ? null
          : (linkedActivityTitle ?? this.linkedActivityTitle),
      projectName: projectName ?? this.projectName,
      isBreak: isBreak ?? this.isBreak,
      pomodoroCycle: pomodoroCycle ?? this.pomodoroCycle,
    );
  }
}
