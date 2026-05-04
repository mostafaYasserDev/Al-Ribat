class WorkSessionItem {
  const WorkSessionItem({
    required this.id,
    required this.name,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    required this.completed,
  });

  final String id;
  final String name;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// User finished the timer vs abandoned early.
  final bool completed;

  int get actualMinutes {
    final end = endedAt ?? startedAt;
    final d = end.difference(startedAt).inMinutes;
    return d < 0 ? 0 : d;
  }
}
