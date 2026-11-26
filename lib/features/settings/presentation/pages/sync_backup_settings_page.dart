import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../application/providers.dart';
import '../../../../core/app_startup.dart';
import '../../../../core/ui_feedback.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../services/backup/local_auto_backup_service.dart';
import '../../../../services/backup_export_service.dart';
import '../../../../services/cloud_sync_service.dart';
import '../widgets/settings_ui_components.dart';

class SyncBackupSettingsPage extends ConsumerStatefulWidget {
  const SyncBackupSettingsPage({super.key});

  @override
  ConsumerState<SyncBackupSettingsPage> createState() =>
      _SyncBackupSettingsPageState();
}

class _SyncBackupSettingsPageState
    extends ConsumerState<SyncBackupSettingsPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) appSnack(context, successMsg);
    } catch (e) {
      if (mounted) appError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidateAll() {
    ref.invalidate(settingsProvider);
    ref.invalidate(activitiesProvider);
    ref.invalidate(workSessionsProvider);
    ref.invalidate(reflectionsProvider);
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(streakProvider);
  }

  Future<BackupRestoreMode?> _askRestoreMode({
    required String title,
  }) async {
    return showDialog<BackupRestoreMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(
          'اختر طريقة استعادة البيانات من الملف:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, BackupRestoreMode.merge),
            child: const Text('دمج مع الحالي'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, BackupRestoreMode.replace),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('استبدال الكل'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndImport() async {
    final mode = await _askRestoreMode(title: 'استيراد نسخة احتياطية');
    if (mode == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final imported = await BackupExportService.importInteractive(mode: mode);
      if (!imported) return;
      _invalidateAll();
      if (mounted) {
        appSnack(
          context,
          mode == BackupRestoreMode.merge
              ? 'تم دمج البيانات المستوردة بنجاح.'
              : 'تم استبدال البيانات بالنسخة الاحتياطية بنجاح.',
        );
      }
    } catch (e) {
      if (mounted) {
        appError(context, e, fallback: 'تعذر استيراد النسخة الاحتياطية.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndRestoreAutoBackup() async {
    final mode = await _askRestoreMode(title: 'استعادة من الملف التلقائي');
    if (mode == null || !mounted) return;
    await _run(() async {
      await LocalAutoBackupService.restoreFromAutoBackup(mode: mode);
      _invalidateAll();
    },
        mode == BackupRestoreMode.merge
            ? 'تم دمج بيانات الملف التلقائي.'
            : 'تمت الاستعادة من الملف التلقائي.');
  }

  Future<void> _pickAutoBackupDirectory(AppSettings settings) async {
    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلد الحفظ التلقائي',
      );
      if (dir == null || dir.trim().isEmpty || !mounted) return;
      await ref.read(settingsProvider.notifier).updateSettings(
            settings.copyWith(
              autoLocalBackupEnabled: true,
              autoLocalBackupPath: dir.trim(),
            ),
          );
      if (mounted) {
        appSnack(context, 'تم تحديث مسار الحفظ التلقائي.');
      }
    } catch (e) {
      if (mounted) {
        appError(
          context,
          e,
          fallback: 'تعذر تغيير المجلد على هذا الجهاز.',
        );
      }
    }
  }

  Future<void> _confirmAndResetSettings() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة ضبط الإعدادات؟'),
        content: const Text(
          'سيتم استعادة جميع الإعدادات (المظهر، الصلاة، الإشعارات، الأمان) إلى قيمها الافتراضية دون المساس بأنشطتك أو تأملاتك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إعادة ضبط'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(() async {
      await ref
          .read(settingsProvider.notifier)
          .updateSettings(AppSettings.defaults);
      ref.invalidate(prayerScheduleProvider);
    }, 'تمت إعادة ضبط الإعدادات للافتراضي.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const FrostedSettingsSliverAppBar(
              title: 'المزامنة والنسخ الاحتياطي',
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<User?>(
                stream: CloudSyncService.authStateChanges,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final signedIn = user != null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SettingsSectionHeader(
                        title: 'المزامنة السحابية (Google)',
                        padding: EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
                      ),
                      SettingsGroupCard(
                        dividerIndent: 16,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    SettingsIconBadge(
                                      icon: signedIn
                                          ? Icons.cloud_done_rounded
                                          : Icons.cloud_outlined,
                                      color: signedIn
                                          ? const Color(0xFF34C759)
                                          : const Color(0xFF007AFF),
                                      size: 40,
                                      iconSize: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            signedIn
                                                ? (user.displayName ??
                                                    'حساب Google')
                                                : 'غير متصل بالسحابة',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            signedIn
                                                ? (user.email ??
                                                    'المزامنة متاحة')
                                                : 'سجّل الدخول لحفظ نسخة سحابية آمنة',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (!AppStartup.isFirebaseReady) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'المزامنة السحابية غير متاحة على هذا الجهاز. بياناتك محفوظة محلياً.',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_busy) ...[
                                  const SizedBox(height: 12),
                                  const ClipRRect(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                    child: LinearProgressIndicator(),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                if (!signedIn)
                                  FilledButton.icon(
                                    onPressed:
                                        _busy || !AppStartup.isFirebaseReady
                                            ? null
                                            : () => _run(() async {
                                                  await CloudSyncService
                                                      .signInWithGoogle();
                                                }, 'تم تسجيل الدخول.'),
                                    icon: const Icon(Icons.login_rounded),
                                    label: const Text('تسجيل الدخول بـ Google'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )
                                else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _busy
                                              ? null
                                              : () => _run(() async {
                                                    await CloudSyncService
                                                        .uploadBackup();
                                                  }, 'تم رفع النسخة السحابية.'),
                                          icon: const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('رفع للسحابة'),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 11),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _busy
                                              ? null
                                              : () => _run(() async {
                                                    await CloudSyncService
                                                        .downloadBackup();
                                                    _invalidateAll();
                                                  }, 'تم استعادة البيانات من السحابة.'),
                                          icon: const Icon(
                                            Icons.cloud_download_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('استعادة'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 11),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(() async {
                                              await CloudSyncService.signOut();
                                            }, 'تم تسجيل الخروج.'),
                                    icon: const Icon(Icons.logout_rounded,
                                        size: 18),
                                    label: const Text('تسجيل الخروج'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SettingsSectionHeader(
                        title: 'النسخ الاحتياطي المحلي (JSON)',
                      ),
                      SettingsGroupCard(
                        children: [
                          SettingsNavTile(
                            icon: Icons.save_alt_rounded,
                            iconColor: const Color(0xFF34C759),
                            title: 'تصدير نسخة احتياطية',
                            subtitle:
                                'حفظ الأنشطة والتأملات والجلسات والإعدادات في ملف',
                            onTap: _busy
                                ? null
                                : () async {
                                    HapticFeedback.lightImpact();
                                    setState(() => _busy = true);
                                    try {
                                      final exported = await BackupExportService
                                          .exportInteractive();
                                      if (exported && context.mounted) {
                                        appSnack(
                                          context,
                                          'تم حفظ النسخة الاحتياطية.',
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        appError(
                                          context,
                                          e,
                                          fallback:
                                              'تعذر تجهيز النسخة الاحتياطية.',
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() => _busy = false);
                                      }
                                    }
                                  },
                          ),
                          SettingsNavTile(
                            icon: Icons.file_upload_outlined,
                            iconColor: const Color(0xFFFF9500),
                            title: 'استيراد نسخة احتياطية',
                            subtitle: 'دمج أو استبدال البيانات بملف JSON سابق',
                            onTap: _busy ? null : _confirmAndImport,
                          ),
                        ],
                      ),
                      const SettingsSectionHeader(
                        title: 'الحفظ التلقائي الفوري في ملف محلي',
                      ),
                      _buildAutoLocalBackupCard(theme, settings),
                      const SettingsSectionFooter(
                        text:
                            'يُحدّث الملف تلقائياً وفورياً مع كل تغيير في أنشطتك أو تأملاتك أو إعداداتك لضمان أمان بياناتك محلياً.',
                      ),
                      const SettingsSectionHeader(title: 'إدارة الإعدادات'),
                      SettingsGroupCard(
                        children: [
                          SettingsNavTile(
                            icon: Icons.restart_alt_rounded,
                            iconColor: const Color(0xFFFF3B30),
                            title: 'إعادة ضبط الإعدادات للافتراضي',
                            subtitle:
                                'استعادة إعدادات التطبيق دون حذف أنشطتك أو تأملاتك',
                            onTap: _busy ? null : _confirmAndResetSettings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoLocalBackupCard(ThemeData theme, AppSettings settings) {
    return ValueListenableBuilder<LocalAutoBackupState>(
      valueListenable: LocalAutoBackupService.statusNotifier,
      builder: (context, status, _) {
        final lastSavedText = status.lastSavedAt == null
            ? 'لم يُحفظ بعد'
            : DateFormat('yyyy/MM/dd – HH:mm:ss', 'ar')
                .format(status.lastSavedAt!.toLocal());

        return SettingsGroupCard(
          dividerIndent: 16,
          children: [
            SettingsSwitchTile(
              icon: Icons.autorenew_rounded,
              iconColor: const Color(0xFF34C759),
              title: 'تفعيل الحفظ التلقائي الفوري',
              subtitle: 'تحديث ملف النسخة المحلية فوراً عند أي تعديل',
              value: settings.autoLocalBackupEnabled,
              onChanged: _busy
                  ? (_) {}
                  : (value) async {
                      await ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(autoLocalBackupEnabled: value),
                          );
                    },
            ),
            if (settings.autoLocalBackupEnabled || status.filePath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'آخر تحديث:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            status.isWriting ? 'جاري الحفظ…' : lastSavedText,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        SettingsStatusPill(
                          label:
                              settings.autoLocalBackupEnabled ? 'نشط' : 'متوقف',
                          color: settings.autoLocalBackupEnabled
                              ? const Color(0xFF34C759)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                    if (status.filePath != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        status.filePath!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (status.lastError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'تعذر الحفظ في المسار المحدد: ${status.lastError}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                    () => LocalAutoBackupService.writeNow(),
                                    'تم تحديث الملف المحلي الآن.',
                                  ),
                          icon: const Icon(Icons.save_rounded, size: 17),
                          label: const Text('حفظ الآن'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                    () => LocalAutoBackupService
                                        .shareAutoBackupFile(),
                                    'تم تجهيز الملف للمشاركة.',
                                  ),
                          icon: const Icon(Icons.share_rounded, size: 17),
                          label: const Text('مشاركة'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _pickAutoBackupDirectory(settings),
                          icon: const Icon(Icons.folder_open_rounded, size: 17),
                          label: const Text('تغيير المجلد'),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              _busy ? null : _confirmAndRestoreAutoBackup,
                          icon: const Icon(Icons.restore_rounded, size: 17),
                          label: const Text('استعادة منه'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
