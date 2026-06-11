import 'package:flutter/material.dart';

Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
  String cancelLabel = 'إلغاء',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

enum ActivityDeleteOption { skipToday, endFuture, deleteCompletely }

Future<ActivityDeleteOption?> showActivityDeleteOptions(BuildContext context, String title) {
  return showDialog<ActivityDeleteOption>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('خيارات الحذف'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('كيف تريد التعامل مع نشاط «$title»؟', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.today, color: Colors.orange),
            title: const Text('تخطي لليوم فقط'),
            subtitle: const Text('لن يظهر اليوم، وسيعود غداً'),
            onTap: () => Navigator.pop(ctx, ActivityDeleteOption.skipToday),
          ),
          ListTile(
            leading: const Icon(Icons.archive, color: Colors.blue),
            title: const Text('إيقاف من اليوم والمستقبل'),
            subtitle: const Text('لن يظهر مستقبلاً لكن يُحفظ في السجل الماضي'),
            onTap: () => Navigator.pop(ctx, ActivityDeleteOption.endFuture),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('حذف نهائي'),
            subtitle: const Text('حذف النشاط تماماً ومسح كل السجلات الخاصة به'),
            onTap: () => Navigator.pop(ctx, ActivityDeleteOption.deleteCompletely),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
      ],
    ),
  );
}
