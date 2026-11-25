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
  @override
  Widget build(BuildContext context) {
    final acts =
        ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
    final all = ProjectAggregate.fromActivities(acts, Theme.of(context));
    final proj = all.where((p) => p.name == widget.projectName).firstOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

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
                  child: PopupMenuButton<String>(
                    tooltip: 'خيارات المشروع',
                    offset: const Offset(0, 44),
                    elevation: 8,
                    color: cardColor,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: isDark ? 0.1 : 0.07),
                        width: 0.7,
                      ),
                    ),
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      if (val == 'rename') {
                        ProjectDetailsDialogs.showRename(
                            context, ref, proj.name);
                      } else if (val == 'delete') {
                        ProjectDetailsDialogs.showDelete(
                            context, ref, proj.name);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem<String>(
                        value: 'rename',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            const Flexible(
                              child: Text(
                                'تعديل اسم المشروع',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'حذف المشروع',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF152036)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 20,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
                        color: cardColor,
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
                  const SizedBox(height: 4),
                  _AddGroupActionCard(
                    accentColor: proj.color,
                    onTap: () => ProjectDetailsDialogs.showAddGroup(
                      context,
                      proj.name,
                      () => setState(() {}),
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

class _AddGroupActionCard extends StatefulWidget {
  const _AddGroupActionCard({
    required this.accentColor,
    required this.onTap,
  });

  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_AddGroupActionCard> createState() => _AddGroupActionCardState();
}

class _AddGroupActionCardState extends State<_AddGroupActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.onSurface
                .withValues(alpha: isDark ? 0.08 : 0.07),
            width: 0.7,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (v) {
              if (_pressed != v) setState(() => _pressed = v);
            },
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: widget.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'إضافة جانب أو مجموعة جديدة',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 20,
                    color: widget.accentColor.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
