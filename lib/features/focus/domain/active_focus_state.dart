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

  bool get canSavePartial {
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    return elapsedMs >= 600000; // 10 minutes
  }

  const ActiveFocusState({
    required this.title,
    required this.plannedMinutes,
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
  });

  ActiveFocusState copyWith({
    String? title,
    int? plannedMinutes,
    DateTime? startedAt,
    int? remainingSeconds,
    int? elapsedSeconds,
    bool? isPaused,
    FocusSessionMode? mode,
    String? linkedActivityId,
    String? linkedActivityTitle,
    String? projectName,
    bool? isBreak,
    int? pomodoroCycle,
  }) {
    return ActiveFocusState(
      title: title ?? this.title,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      startedAt: startedAt ?? this.startedAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      mode: mode ?? this.mode,
      linkedActivityId: linkedActivityId ?? this.linkedActivityId,
      linkedActivityTitle: linkedActivityTitle ?? this.linkedActivityTitle,
      projectName: projectName ?? this.projectName,
      isBreak: isBreak ?? this.isBreak,
      pomodoroCycle: pomodoroCycle ?? this.pomodoroCycle,
    );
  }
}
