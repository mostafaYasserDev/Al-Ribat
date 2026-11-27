import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
import '../../../../services/calendar/google_calendar_sync_service.dart';
import '../../../../services/calendar/ics_export_service.dart';
import '../../../../services/cloud_sync_service.dart';
import '../widgets/settings_action_sheet.dart';
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
  final _importTileKey = GlobalKey();
  final _locationBtnKey = GlobalKey();
  final _cloudRestoreBtnKey = GlobalKey();
  final _resetTileKey = GlobalKey();

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
    required GlobalKey anchorKey,
    required String title,
  }) {
    return showAnchoredSettingsMenu<BackupRestoreMode>(
      context: context,
      anchorKey: anchorKey,
      title: title,
      subtitle: 'اختر كيف تريد التعامل مع بياناتك الحالية:',
      options: const [
        AnchoredMenuOption(
          value: BackupRestoreMode.merge,
          title: 'دمج مع البيانات الحالية',
          subtitle: 'يُبقي على بياناتك ويضيف إليها محتوى الملف',
          icon: Icons.merge_rounded,
          color: Color(0xFF007AFF),
        ),
        AnchoredMenuOption(
          value: BackupRestoreMode.replace,
          title: 'استبدال البيانات الحالية',
          subtitle: 'يمسح البيانات الحالية ويستعيد الملف فقط',
          icon: Icons.delete_sweep_rounded,
          isDestructive: true,
        ),
      ],
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final cred = await CloudSyncService.signInWithGoogle();
      if (cred != null && mounted) {
        appSnack(context, 'تم تسجيل الدخول بنجاح.');
      }
    } catch (e) {
      if (mounted) appError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndCloudRestore() async {
    final mode = await _askRestoreMode(
      anchorKey: _cloudRestoreBtnKey,
      title: 'استعادة من Google Drive',
    );
    if (mode == null || !mounted) return;
    await _run(() async {
      await CloudSyncService.downloadBackup(mode: mode);
      _invalidateAll();
    },
        mode == BackupRestoreMode.merge
            ? 'تم دمج البيانات من السحابة بنجاح.'
            : 'تمت الاستعادة من السحابة بنجاح.');
  }

  Future<void> _syncGoogleCalendar(AppSettings settings) async {
    setState(() => _busy = true);
    try {
      final schedule = await ref.read(todayPrayerScheduleProvider.future);
      final activities = await ref.read(activityRepositoryProvider).loadAll();
      final res = await GoogleCalendarSyncService.syncTodaySchedule(
        schedule: schedule,
        activities: activities,
        settings: settings,
      );
      if (mounted) {
        appSnack(
          context,
          'تمت مزامنة ${res.syncedEvents} حدث مع تقويم الرباط في Google.',
        );
      }
    } catch (e) {
      if (mounted) {
        appError(context, e, fallback: 'تعذر المزامنة مع Google Calendar.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportIcsSchedule(AppSettings settings) async {
    setState(() => _busy = true);
    try {
      final schedule = await ref.read(todayPrayerScheduleProvider.future);
      final activities = await ref.read(activityRepositoryProvider).loadAll();
      final exported = await IcsExportService.exportInteractive(
        schedule: schedule,
        activities: activities,
        settings: settings,
      );
      if (exported && mounted) {
        appSnack(context, 'تم تجهيز ملف التقويم (.ics).');
      }
    } catch (e) {
      if (mounted) {
        appError(context, e, fallback: 'تعذر تصدير ملف التقويم.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndImport() async {
    final mode = await _askRestoreMode(
      anchorKey: _importTileKey,
      title: 'استيراد نسخة احتياطية',
    );
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

  Future<void> _shareAutoBackup() async {
    setState(() => _busy = true);
    try {
      final shared = await LocalAutoBackupService.shareAutoBackupFile();
      if (shared && mounted) {
        final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
        appSnack(
          context,
          isMobile ? 'تم تجهيز الملف للمشاركة.' : 'تم حفظ نسخة من الملف.',
        );
      }
    } catch (e) {
      if (mounted) {
        appError(context, e, fallback: 'تعذر مشاركة الملف.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showLocationMenu(
    AppSettings settings,
    String? currentPath,
  ) async {
    final isDesktop =
        !kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
    final action = await showAnchoredSettingsMenu<String>(
      context: context,
      anchorKey: _locationBtnKey,
      title: 'مكان ملف الحفظ التلقائي',
      options: [
        const AnchoredMenuOption(
          value: 'change',
          title: 'تغيير مكان المستند',
          subtitle: 'اختر مجلداً أو مساراً جديداً للملف',
          icon: Icons.drive_file_move_rounded,
          color: Color(0xFFFF9500),
        ),
        if (isDesktop)
          const AnchoredMenuOption(
            value: 'open',
            title: 'فتح المجلد الحالي',
            subtitle: 'عرض الملف مباشرة في مدير الملفات',
            icon: Icons.folder_open_rounded,
            color: Color(0xFF007AFF),
          ),
        if (settings.autoLocalBackupPath != null)
          const AnchoredMenuOption(
            value: 'reset',
            title: 'العودة للمسار الافتراضي',
            subtitle: 'استخدام مجلد التطبيق الافتراضي',
            icon: Icons.settings_backup_restore_rounded,
            color: Color(0xFF5856D6),
          ),
      ],
    );
    if (action == null || !mounted) return;

    if (action == 'open') {
      await _run(
        () => LocalAutoBackupService.openContainingFolder(),
        'تم فتح المجلد.',
      );
    } else if (action == 'reset') {
      await _run(() async {
        await ref.read(settingsProvider.notifier).updateSettings(
              settings.copyWith(
                autoLocalBackupEnabled: true,
                clearAutoLocalBackupPath: true,
              ),
            );
      }, 'تمت استعادة المسار الافتراضي.');
    } else if (action == 'change') {
      await _pickAutoBackupLocation(settings, currentPath);
    }
  }

  Future<void> _pickAutoBackupLocation(
    AppSettings settings,
    String? currentPath,
  ) async {
    try {
      String? initialDir;
      if (currentPath != null) {
        final parent = File(currentPath).parent;
        if (await parent.exists()) {
          initialDir = parent.path;
        }
      }

      String? chosenPath;
      final isDesktop = !kIsWeb &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
      if (isDesktop) {
        chosenPath = await FilePicker.platform.saveFile(
          dialogTitle: 'اختر مكان حفظ الملف التلقائي',
          fileName: currentPath != null
              ? File(currentPath).uri.pathSegments.last
              : LocalAutoBackupService.fileName,
          initialDirectory: initialDir,
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
        if (chosenPath != null && !chosenPath.toLowerCase().endsWith('.json')) {
          chosenPath = '$chosenPath.json';
        }
      } else {
        chosenPath = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'اختر مجلد الحفظ التلقائي',
          initialDirectory: initialDir,
        );
      }

      if (chosenPath == null || chosenPath.trim().isEmpty || !mounted) return;
      await ref.read(settingsProvider.notifier).updateSettings(
            settings.copyWith(
              autoLocalBackupEnabled: true,
              autoLocalBackupPath: chosenPath.trim(),
            ),
          );
      if (mounted) {
        appSnack(context, 'تم تغيير مكان المستند وحفظه.');
      }
    } catch (e) {
      if (mounted) {
        appError(
          context,
          e,
          fallback: 'تعذر تغيير مكان الملف على هذا الجهاز.',
        );
      }
    }
  }

  Future<void> _confirmAndResetSettings() async {
    final ok = await showAnchoredSettingsMenu<bool>(
      context: context,
      anchorKey: _resetTileKey,
      title: 'إعادة ضبط الإعدادات؟',
      subtitle: 'تُستعاد الإعدادات الافتراضية دون حذف أنشطتك أو تأملاتك.',
      options: const [
        AnchoredMenuOption(
          value: true,
          title: 'تأكيد إعادة الضبط',
          subtitle: 'المظهر، الصلاة، الإشعارات، والأمان',
          icon: Icons.restart_alt_rounded,
          isDestructive: true,
        ),
      ],
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
                                            : _signInWithGoogle,
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
                                                  }, 'تم رفع النسخة إلى Google Drive.'),
                                          icon: const Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 18,
                                          ),
                                          label: const Text('رفع لـ Drive'),
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
                                        child: KeyedSubtree(
                                          key: _cloudRestoreBtnKey,
                                          child: OutlinedButton.icon(
                                            onPressed: _busy
                                                ? null
                                                : _confirmAndCloudRestore,
                                            icon: const Icon(
                                              Icons.cloud_download_outlined,
                                              size: 18,
                                            ),
                                            label: const Text('استعادة'),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 11),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
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
                        title: 'التكامل مع التقويم',
                      ),
                      SettingsGroupCard(
                        children: [
                          SettingsNavTile(
                            icon: Icons.event_available_rounded,
                            iconColor: const Color(0xFF007AFF),
                            title: 'مزامنة أوقات اليوم مع Google Calendar',
                            subtitle: signedIn
                                ? 'يُنشئ تقويم «الرباط — أوقات الصلاة» دون إزعاج تقويمك'
                                : 'يتطلب تسجيل الدخول بحساب Google أولاً',
                            onTap: _busy || !signedIn
                                ? null
                                : () => _syncGoogleCalendar(settings),
                          ),
                          SettingsNavTile(
                            icon: Icons.calendar_month_rounded,
                            iconColor: const Color(0xFF5856D6),
                            title: 'تصدير جدول اليوم (.ics)',
                            subtitle:
                                'يعمل مع Apple Calendar وOutlook وGoogle Calendar بدون تسجيل',
                            onTap: _busy
                                ? null
                                : () => _exportIcsSchedule(settings),
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
                          KeyedSubtree(
                            key: _importTileKey,
                            child: SettingsNavTile(
                              icon: Icons.file_upload_outlined,
                              iconColor: const Color(0xFFFF9500),
                              title: 'استيراد نسخة احتياطية',
                              subtitle:
                                  'دمج أو استبدال البيانات بملف JSON سابق',
                              onTap: _busy ? null : _confirmAndImport,
                            ),
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
                          KeyedSubtree(
                            key: _resetTileKey,
                            child: SettingsNavTile(
                              icon: Icons.restart_alt_rounded,
                              iconColor: const Color(0xFFFF3B30),
                              title: 'إعادة ضبط الإعدادات للافتراضي',
                              subtitle:
                                  'استعادة إعدادات التطبيق دون حذف أنشطتك أو تأملاتك',
                              onTap: _busy ? null : _confirmAndResetSettings,
                            ),
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
    final isDark = theme.brightness == Brightness.dark;
    return ValueListenableBuilder<LocalAutoBackupState>(
      valueListenable: LocalAutoBackupService.statusNotifier,
      builder: (context, status, _) {
        final lastSavedText = status.lastSavedAt == null
            ? 'لم يُحفظ بعد'
            : DateFormat('yyyy/MM/dd – HH:mm:ss', 'ar')
                .format(status.lastSavedAt!.toLocal());
        final expanded =
            settings.autoLocalBackupEnabled || status.filePath != null;

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
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      status.isWriting
                                          ? Icons.sync_rounded
                                          : Icons.check_circle_rounded,
                                      size: 16,
                                      color: settings.autoLocalBackupEnabled
                                          ? const Color(0xFF34C759)
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.45),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        status.isWriting
                                            ? 'جاري الحفظ…'
                                            : 'آخر تحديث: $lastSavedText',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SettingsStatusPill(
                                      label: settings.autoLocalBackupEnabled
                                          ? 'نشط'
                                          : 'متوقف',
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
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.56),
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _TelegramQuickAction(
                                  icon: Icons.save_rounded,
                                  label: 'حفظ الآن',
                                  color: const Color(0xFF34C759),
                                  enabled: !_busy,
                                  onTap: () => _run(
                                    () => LocalAutoBackupService.writeNow(),
                                    'تم تحديث الملف المحلي الآن.',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _TelegramQuickAction(
                                  icon: Icons.ios_share_rounded,
                                  label: 'مشاركة',
                                  color: const Color(0xFF007AFF),
                                  enabled: !_busy,
                                  onTap: _shareAutoBackup,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: KeyedSubtree(
                                  key: _locationBtnKey,
                                  child: _TelegramQuickAction(
                                    icon: Icons.folder_rounded,
                                    label: 'مكان الملف',
                                    color: const Color(0xFFFF9500),
                                    enabled: !_busy,
                                    onTap: () => _showLocationMenu(
                                      settings,
                                      status.filePath,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _TelegramQuickAction extends StatelessWidget {
  const _TelegramQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg =
        isDark ? color.withValues(alpha: 0.14) : color.withValues(alpha: 0.10);

    return PressableScale(
      enabled: enabled,
      onTap: onTap,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          splashColor: color.withValues(alpha: 0.14),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
