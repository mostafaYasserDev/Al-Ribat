import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../domain/entities/activity_item.dart';
import '../data/project_metadata_service.dart';

class ProjectAggregate {
  final String name;
  final Color color;
  final IconData icon;
  final Map<String, List<ActivityItem>> groups;

  /// Activities linked to this project without any specific group/aspect.
  final List<ActivityItem> generalTasks;

  const ProjectAggregate({
    required this.name,
    required this.color,
    required this.icon,
    required this.groups,
    this.generalTasks = const [],
  });

  int get totalTasks =>
      groups.values.fold(0, (sum, l) => sum + l.length) + generalTasks.length;

  static int _countDone(List<ActivityItem> items, String todayStr) {
    return items.where((a) {
      return a.repetition == ActivityRepetition.once
          ? a.historyDates.isNotEmpty
          : a.isDoneOn(todayStr);
    }).length;
  }

  int get completedTasks {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final groupedDone = groups.values.fold<int>(
      0,
      (sum, l) => sum + _countDone(l, todayStr),
    );
    return groupedDone + _countDone(generalTasks, todayStr);
  }

  double get progress =>
      totalTasks > 0 ? (completedTasks / totalTasks).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => totalTasks > 0 && completedTasks == totalTasks;

  static List<ProjectAggregate> fromActivities(
    List<ActivityItem> activities,
    ThemeData theme,
  ) {
    final map = <String, Map<String, List<ActivityItem>>>{};
    final generalMap = <String, List<ActivityItem>>{};

    for (final act in activities) {
      final p = act.projectName?.trim();
      if (p == null || p.isEmpty) continue;
      map.putIfAbsent(p, () => {});
      generalMap.putIfAbsent(p, () => []);
      final g = act.groupName?.trim();
      if (g != null && g.isNotEmpty) {
        map[p]!.putIfAbsent(g, () => []);
        map[p]![g]!.add(act);
      } else {
        generalMap[p]!.add(act);
      }
    }

    // Also include saved projects that may have 0 activities
    for (final savedName in ProjectGroupsService.getAllProjectNames()) {
      map.putIfAbsent(savedName, () => {});
      generalMap.putIfAbsent(savedName, () => []);
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
      final generalTasks = generalMap[pName] ?? const <ActivityItem>[];
      Color? c;
      IconData? icon;

      final info = ProjectGroupsService.getProjectInfo(pName);
      if (info?.colorHex != null) {
        c = AppIcons.parseColor(info!.colorHex);
      }
      if (info?.iconName != null) {
        icon = AppIcons.getIconData(info!.iconName);
      }

      for (final acts in [...groups.values, generalTasks]) {
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
        generalTasks: generalTasks,
      );
    }).toList();
  }
}
