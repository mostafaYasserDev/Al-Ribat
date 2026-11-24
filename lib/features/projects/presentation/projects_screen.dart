import 'package:flutter/material.dart';
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
import 'widgets/projects_grid_view.dart';
import 'widgets/projects_overview_header.dart';
import 'widgets/project_templates_sheet.dart';

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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المشاريع والأهداف الكبرى'),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded),
              tooltip: 'قوالب ملهمة',
              onPressed: () => _openTemplates(context),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'projects_fab',
          onPressed: () => _openNewProject(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('مشروع جديد'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
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
                MaterialPageRoute(
                    builder: (_) => ProjectDetailsScreen(projectName: p.name)),
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
                onOpenDetails: (act) =>
                    ProjectTaskActions.openDetails(context, ref, act),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openTemplates(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
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

  void _openNewProject(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NewProjectDialog(
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
          appSnack(this.context, 'تم إنشاء مشروع "$projectName" بنجاح.');
        },
      ),
    );
  }
}
