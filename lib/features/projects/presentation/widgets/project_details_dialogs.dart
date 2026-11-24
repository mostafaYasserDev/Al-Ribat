import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/ui_feedback.dart';
import '../../data/project_metadata_service.dart';

class ProjectDetailsDialogs {
  static void showAddGroup(
    BuildContext context,
    String projectName,
    VoidCallback onRefresh,
  ) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جانب أو مجموعة جديدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم المجموعة *',
                hintText: 'مثال: الجانب التقني، التسويق...',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'الوصف (اختياري)',
                hintText: 'مثال: كل ما يتعلق بالبرمجة والتطوير...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final g = nameCtrl.text.trim();
              if (g.isNotEmpty) {
                Navigator.pop(ctx);
                await ProjectGroupsService.saveGroup(
                  projectName,
                  g,
                  descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                );
                onRefresh();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  static void showRename(
    BuildContext context,
    WidgetRef ref,
    String oldName,
  ) {
    final ctrl = TextEditingController(text: oldName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل اسم المشروع'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'الاسم الجديد'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final n = ctrl.text.trim();
              if (n.isNotEmpty && n != oldName) {
                Navigator.pop(ctx);
                await ref
                    .read(activitiesProvider.notifier)
                    .renameProject(oldName, n);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  static void showDelete(
    BuildContext context,
    WidgetRef ref,
    String projectName,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('حذف "$projectName"'),
        content: const Text('هل تريد حذف المشروع بجميع مهامه؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(activitiesProvider.notifier)
                  .deleteProject(projectName, deleteActivities: true);
              if (context.mounted) {
                Navigator.pop(context);
                appSnack(context, 'تم حذف المشروع بمهامه.');
              }
            },
            child: const Text('حذف المشروع'),
          ),
        ],
      ),
    );
  }
}
