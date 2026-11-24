import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/ui_feedback.dart';
import '../../../domain/entities/activity_item.dart';
import '../../widgets/add_activity_sheet.dart';
import '../parts/project_models.dart';
import '../parts/project_task_actions.dart';
import 'project_details_dialogs.dart';
import 'project_details_header.dart';
import 'project_group_accordion.dart';
import 'project_groups_service.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  const ProjectDetailsScreen({super.key, required this.projectName});
  final String projectName;

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final acts =
        ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
    final all = ProjectAggregate.fromActivities(acts, Theme.of(context));
    final proj = all.where((p) => p.name == widget.projectName).firstOrNull;

    if (proj == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.projectName)),
        body: const Center(child: Text('المشروع غير موجود أو تم حذفه.')),
      );
    }

    final savedGroups = ProjectGroupsService.getGroups(proj.name);
    final groupMap = <String, List<ActivityItem>>{};
    for (final sg in savedGroups) {
      groupMap[sg.name] = proj.groups[sg.name] ?? [];
    }
    for (final g in proj.groups.keys) {
      groupMap.putIfAbsent(g, () => proj.groups[g]!);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(proj.name),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'rename') {
                  ProjectDetailsDialogs.showRename(context, ref, proj.name);
                }
                if (val == 'delete') {
                  ProjectDetailsDialogs.showDelete(context, ref, proj.name);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'rename', child: Text('تعديل اسم المشروع')),
                const PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('حذف المشروع', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            ProjectDetailsHeader(
              project: proj,
              onRename: () =>
                  ProjectDetailsDialogs.showRename(context, ref, proj.name),
              onDelete: () =>
                  ProjectDetailsDialogs.showDelete(context, ref, proj.name),
            ),
            const SizedBox(height: 16),
            if (groupMap.isEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 40, color: proj.color.withValues(alpha: 0.6)),
                    const SizedBox(height: 8),
                    Text(
                      'لا توجد جوانب أو مجموعات بعد في هذا المشروع',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'أضف أول جانب لتنظيم مهام المشروع بداخله',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...groupMap.entries.map((e) {
              final desc = savedGroups
                  .where((g) => g.name == e.key)
                  .firstOrNull
                  ?.description;

              return ProjectGroupAccordion(
                groupName: e.key,
                description: desc,
                tasks: e.value,
                color: proj.color,
                onToggleDone: (t) =>
                    ProjectTaskActions.toggleDone(context, ref, t),
                onOpenDetails: (t) =>
                    ProjectTaskActions.openDetails(context, ref, t),
                onAddTask: () => _openAddTaskSheet(proj.name, e.key),
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ProjectDetailsDialogs.showAddGroup(
                context,
                proj.name,
                () => setState(() {}),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة مجموعة / جانب جديد'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddTaskSheet(String projectName, String groupName) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddActivitySheet(
        initialProject: projectName,
        initialGroup: groupName,
        isIndependentInitial: true,
        onSave: (activity) async {
          await ref.read(activitiesProvider.notifier).addActivity(
                activity.copyWith(
                  projectName: projectName,
                  groupName: groupName,
                  repetition: ActivityRepetition.once,
                ),
              );
          lightSuccessHaptic();
          if (mounted) appSnack(context, 'أُضيفت المهمة إلى $groupName بنجاح.');
          return true;
        },
      ),
    );
  }
}
