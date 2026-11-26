import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../core/app_startup.dart';
import '../../../../core/ui_feedback.dart';
import '../../../../domain/entities/app_settings.dart';
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

  Future<void> _confirmAndImport() async {
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
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final imported = await BackupExportService.importInteractive();
      if (!imported) return;
      _invalidateAll();
      if (mounted) appSnack(context, 'تم الاستيراد بنجاح.');
    } catch (e) {
      if (mounted) {
        appError(context, e, fallback: 'تعذر استيراد النسخة الاحتياطية.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
                            subtitle: 'استبدال البيانات الحالية بملف JSON سابق',
                            onTap: _busy ? null : _confirmAndImport,
                          ),
                        ],
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
}
