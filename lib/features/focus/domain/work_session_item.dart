class WorkSessionItem {
  const WorkSessionItem({
    required this.id,
    required this.name,
    required this.plannedMinutes,
    required this.startedAt,
    required this.endedAt,
    this.completed = true,
  });

  final String id;
  final String name;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime endedAt;
  final bool completed;

  int get actualMinutes {
    final d = endedAt.difference(startedAt).inMinutes;
    return d < 0 ? 0 : d;
  }

  WorkSessionItem copyWith({
    String? id,
    String? name,
    int? plannedMinutes,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? completed,
  }) {
    return WorkSessionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      completed: completed ?? this.completed,
    );
  }
}
