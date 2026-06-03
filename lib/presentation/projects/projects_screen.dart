import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../domain/entities/activity_item.dart';
import '../widgets/add_activity_sheet.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];

    // Grouping: Project -> Group -> List<ActivityItem>
    final grouped = <String, Map<String, List<ActivityItem>>>{};

    for (final act in activities) {
      final pName = (act.projectName != null && act.projectName!.isNotEmpty) ? act.projectName! : 'عام (بدون مشروع)';
      final gName = (act.groupName != null && act.groupName!.isNotEmpty) ? act.groupName! : 'أنشطة عامة';

      grouped.putIfAbsent(pName, () => {});
      grouped[pName]!.putIfAbsent(gName, () => []);
      grouped[pName]![gName]!.add(act);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المشاريع والمجموعات'),
        ),
      body: grouped.isEmpty
          ? const Center(child: Text('لا توجد أنشطة مضافة بعد.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final pName = grouped.keys.elementAt(index);
                final groups = grouped[pName]!;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: ExpansionTile(
                    title: Text(
                      pName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    initiallyExpanded: true,
                    children: groups.entries.map((groupEntry) {
                      final gName = groupEntry.key;
                      final gActs = groupEntry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ...gActs.map((act) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: act.colorHex != null
                                        ? Color(int.parse(act.colorHex!.replaceFirst('#', '0xFF')))
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      _getIconData(act.iconName),
                                      size: 18,
                                      color: act.colorHex != null ? Colors.white : null,
                                    ),
                                  ),
                                  title: Text(act.title),
                                  subtitle: Text(act.type == ActivityType.independent ? 'نشاط حر' : 'مرتبط بصلاة'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () {
                                      _editActivity(context, ref, act);
                                    },
                                  ),
                                )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
      ),
    );
  }

  void _editActivity(BuildContext context, WidgetRef ref, ActivityItem act) async {
    final updated = await showModalBottomSheet<ActivityItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AddActivitySheet(
        initialActivity: act,
        onSave: (h) async {
          Navigator.of(ctx).pop(h);
          return true;
        },
      ),
    );
    if (updated != null) {
      await ref.read(activitiesProvider.notifier).updateActivity(updated);
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'mosque':
        return Icons.mosque;
      case 'book':
        return Icons.book;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'water_drop':
        return Icons.water_drop;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'menu_book':
        return Icons.menu_book;
      case 'favorite':
        return Icons.favorite;
      case 'work':
        return Icons.work;
      case 'directions_run':
        return Icons.directions_run;
      case 'local_dining':
        return Icons.local_dining;
      case 'nightlight_round':
        return Icons.nightlight_round;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.task_alt;
    }
  }
}
