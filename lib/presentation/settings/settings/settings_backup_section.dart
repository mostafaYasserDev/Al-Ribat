part of '../settings_screen.dart';

extension _SettingsBackupCards on _SettingsScreenState {
  Widget _buildBackupExportCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.save_alt_outlined),
        title: const Text('نسخ احتياطي (JSON)'),
        subtitle: const Text(
          'الأنشطة، التأملات، الجلسات، وإعدادات التطبيق — احفظ الملف حيث تريد أو شاركه.',
        ),
        onTap: () async {
          HapticFeedback.lightImpact();
          try {
            await BackupExportService.exportInteractive();
            if (context.mounted) {
              appSnack(context, 'تم تجهيز النسخة.');
            }
          } catch (e) {
            if (context.mounted) {
              appError(context, e, fallback: 'تعذر تجهيز النسخة الاحتياطية.');
            }
          }
        },
      ),
    );
  }

  Widget _buildBackupImportCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.file_upload_outlined),
        title: const Text('استيراد نسخة احتياطية (JSON)'),
        subtitle: const Text(
          'يجب أن يكون بنفس بنية التصدير الحالية. سيتم استبدال البيانات الحالية.',
        ),
        onTap: () async {
          HapticFeedback.lightImpact();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('استيراد واستبدال البيانات؟'),
              content: const Text(
                'سيتم استبدال الأنشطة والتأملات والجلسات والإعدادات الحالية ببيانات الملف.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('استيراد'),
                ),
              ],
            ),
          );
          if (ok != true || !context.mounted) return;
          try {
            await BackupExportService.importInteractive();
            ref.invalidate(settingsProvider);
            ref.invalidate(activitiesProvider);
            ref.invalidate(workSessionsProvider);
            ref.invalidate(reflectionsProvider);
            ref.invalidate(prayerScheduleProvider);
            ref.invalidate(streakProvider);
            if (context.mounted) {
              appSnack(context, 'تم الاستيراد بنجاح.');
            }
          } catch (e) {
            if (context.mounted) {
              appError(context, e, fallback: 'تعذر استيراد النسخة الاحتياطية.');
            }
          }
        },
      ),
    );
  }
}
