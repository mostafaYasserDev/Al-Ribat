import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../domain/entities/activity_item.dart';
import '../data/project_metadata_service.dart';

class ProjectAggregate {
  final String name;
  final Color color;
  final IconData icon;
  final Map<String, List<ActivityItem>> groups;

  const ProjectAggregate({
    required this.name,
    required this.color,
    required this.icon,
    required this.groups,
  });

  int get totalTasks => groups.values.fold(0, (sum, l) => sum + l.length);

  int get completedTasks => groups.values.fold(
        0,
        (sum, l) =>
            sum +
            l.where((a) {
              final now = DateTime.now();
              final todayStr =
                  "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
              return a.repetition == ActivityRepetition.once
                  ? a.historyDates.isNotEmpty
                  : a.isDoneOn(todayStr);
            }).length,
      );

  double get progress =>
      totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => totalTasks > 0 && completedTasks == totalTasks;

  static List<ProjectAggregate> fromActivities(
    List<ActivityItem> activities,
    ThemeData theme,
  ) {
    final map = <String, Map<String, List<ActivityItem>>>{};

    for (final act in activities) {
      final p = act.projectName?.trim();
      if (p == null || p.isEmpty) continue;
      final g = (act.groupName != null && act.groupName!.trim().isNotEmpty)
          ? act.groupName!.trim()
          : 'المرحلة الأولى';
      map.putIfAbsent(p, () => {});
      map[p]!.putIfAbsent(g, () => []);
      map[p]![g]!.add(act);
    }

    // Also include saved projects that may have 0 activities
    for (final savedName in ProjectGroupsService.getAllProjectNames()) {
      map.putIfAbsent(savedName, () => {});
    }

    final colors = [
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.purple,
      Colors.amber.shade800,
      Colors.blueGrey,
    ];

    return map.entries.map((e) {
      final pName = e.key;
      final groups = e.value;
      Color? c;
      IconData? icon;

      final info = ProjectGroupsService.getProjectInfo(pName);
      if (info?.colorHex != null) {
        c = AppIcons.parseColor(info!.colorHex);
      }
      if (info?.iconName != null) {
        icon = AppIcons.getIconData(info!.iconName);
      }

      for (final acts in groups.values) {
        for (final a in acts) {
          c ??= AppIcons.parseColor(a.colorHex);
          if (icon == null && a.iconName != null) {
            icon = AppIcons.getIconData(a.iconName);
          }
        }
      }

      return ProjectAggregate(
        name: pName,
        color: c ?? colors[pName.hashCode.abs() % colors.length],
        icon: icon ?? Icons.folder_special_rounded,
        groups: groups,
      );
    }).toList();
  }
}
