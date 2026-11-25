import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import 'package:al_ribat/presentation/widgets/add_activity_sheet.dart';
import '../data/project_metadata_service.dart';
import '../domain/project_aggregate.dart';
import 'widgets/project_details_dialogs.dart';
import 'widgets/project_details_header.dart';
import 'widgets/project_group_accordion.dart';
import 'widgets/project_task_actions.dart';

class ProjectDetailsScreen extends ConsumerStatefulWidget {
  const ProjectDetailsScreen({super.key, required this.projectName});
  final String projectName;

  @override
  ConsumerState<ProjectDetailsScreen> createState() =>
      _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ConsumerState<ProjectDetailsScreen> {
  void _showProjectActionsSheet(String projectName) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: sheetBg,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('تعديل اسم المشروع'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ProjectDetailsDialogs.showRename(context, ref, projectName);
                  },
                ),
                Divider(
                  height: 0.6,
                  thickness: 0.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'حذف المشروع',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ProjectDetailsDialogs.showDelete(context, ref, projectName);
                  },
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final acts =
        ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
    final all = ProjectAggregate.fromActivities(acts, Theme.of(context));
    final proj = all.where((p) => p.name == widget.projectName).firstOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (proj == null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: Text(widget.projectName)),
          body: const Center(child: Text('المشروع غير موجود أو تم حذفه.')),
        ),
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
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Text(
                proj.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Material(
                    color: isDark
                        ? const Color(0xFF152036)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showProjectActionsSheet(proj.name),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.6),
                child: Container(
                  height: 0.6,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: isDark ? 0.08 : 0.06),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ProjectDetailsHeader(
                    project: proj,
                    onRename: () => ProjectDetailsDialogs.showRename(
                        context, ref, proj.name),
                    onDelete: () => ProjectDetailsDialogs.showDelete(
                        context, ref, proj.name),
                  ),
                  const SizedBox(height: 16),
                  if (groupMap.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 26,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ??
                            (isDark ? const Color(0xFF111B2E) : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: isDark ? 0.08 : 0.07),
                          width: 0.7,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: proj.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.folder_open_rounded,
                              size: 28,
                              color: proj.color,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'لا توجد جوانب أو مجموعات بعد في هذا المشروع',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أضف أول جانب لتنظيم مهام المشروع بداخله',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
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
                  const SizedBox(height: 6),
                  FilledButton.tonalIcon(
                    onPressed: () => ProjectDetailsDialogs.showAddGroup(
                      context,
                      proj.name,
                      () => setState(() {}),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('إضافة مجموعة / جانب جديد'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ]),
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
