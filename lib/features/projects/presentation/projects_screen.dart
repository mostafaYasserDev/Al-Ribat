import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import 'package:al_ribat/domain/entities/activity_item.dart';
import '../data/project_metadata_service.dart';
import '../domain/project_aggregate.dart';
import 'project_details_screen.dart';
import 'widgets/general_tasks_bottom_card.dart';
import 'widgets/new_project_dialog.dart';
import 'widgets/project_task_actions.dart';
import 'widgets/project_templates_sheet.dart';
import 'widgets/projects_grid_view.dart';
import 'widgets/projects_overview_header.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  @override
  Widget build(BuildContext context) {
    final acts = ref.watch(activitiesProvider).valueOrNull ?? const [];
    final projects = ProjectAggregate.fromActivities(acts, Theme.of(context));
    final general = acts
        .where((a) => a.projectName == null || a.projectName!.isEmpty)
        .toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              stretch: true,
              expandedHeight: 96,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              actions: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Tooltip(
                    message: 'قوالب ملهمة',
                    child: Material(
                      color: isDark
                          ? const Color(0xFF152036)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _openTemplates(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 20,
                  bottom: 14,
                  end: 72,
                ),
                centerTitle: false,
                title: Text(
                  'المشاريع والأهداف',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (projects.isNotEmpty) ...[
                    ProjectsOverviewHeader(
                      projects: projects,
                      onOpenTemplates: () => _openTemplates(context),
                    ),
                    const SizedBox(height: 14),
                  ],
                  ProjectsGridView(
                    projects: projects,
                    onSelectProject: (p) => Navigator.push(
                      context,
                      CupertinoPageRoute<void>(
                        builder: (_) =>
                            ProjectDetailsScreen(projectName: p.name),
                      ),
                    ),
                    onOpenTemplates: () => _openTemplates(context),
                    onNewProject: () => _openNewProject(context),
                  ),
                  if (general.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    GeneralTasksBottomCard(
                      tasks: general,
                      onToggleDone: (act) =>
                          ProjectTaskActions.toggleDone(context, ref, act),
                      onOpenDetails: (act, anchorCtx) =>
                          ProjectTaskActions.openDetails(anchorCtx, ref, act),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTemplates(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectTemplatesSheet(onSelect: (t) async {
        final now = DateTime.now();
        final list = <ActivityItem>[];
        for (final entry in t.groups.entries) {
          await ProjectGroupsService.saveGroup(t.title, entry.key, null);
          for (final title in entry.value) {
            list.add(ActivityItem(
              id: (now.microsecondsSinceEpoch + list.length).toString(),
              title: title,
              createdAt: now,
              repetition: ActivityRepetition.once,
              projectName: t.title,
              groupName: entry.key,
              colorHex: t.colorHex,
            ));
          }
        }
        await ref.read(activitiesProvider.notifier).addMultipleActivities(list);
        if (!mounted) return;
        appSnack(this.context, 'تم إنشاء مشروع "${t.title}".');
      }),
    );
  }

  void _openNewProject(BuildContext sourceContext) {
    NewProjectDialog.open(
      context,
      sourceContext: sourceContext,
      sourceColor: Theme.of(context).colorScheme.primaryContainer,
      onCreate: ({
        required projectName,
        description,
        iconName,
        colorHex,
      }) async {
        await ProjectGroupsService.saveProjectInfo(
          projectName,
          description: description,
          iconName: iconName,
          colorHex: colorHex,
        );
        if (!mounted) return;
        setState(() {});
        appSnack(context, 'تم إنشاء مشروع "$projectName" بنجاح.');
      },
    );
  }
}
