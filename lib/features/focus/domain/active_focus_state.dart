class ActiveFocusState {
  final String title;
  final int plannedMinutes;
  final DateTime startedAt;
  final int remainingSeconds;
  final bool isPaused;

  bool get canSavePartial {
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    return elapsedMs >= 600000; // 10 minutes
  }

  const ActiveFocusState({
    required this.title,
    required this.plannedMinutes,
    required this.startedAt,
    required this.remainingSeconds,
    this.isPaused = false,
  });

  ActiveFocusState copyWith({
    String? title,
    int? plannedMinutes,
    DateTime? startedAt,
    int? remainingSeconds,
    bool? isPaused,
  }) {
    return ActiveFocusState(
      title: title ?? this.title,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      startedAt: startedAt ?? this.startedAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
