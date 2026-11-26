import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/app_startup.dart';
import '../../../core/security/app_security.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../services/cloud_sync_service.dart';
import 'pages/about_app_screen.dart';
import 'pages/notifications_timing_settings_page.dart';
import 'pages/prayer_location_settings_page.dart';
import 'pages/sync_backup_settings_page.dart';
import 'widgets/app_lock_sheet.dart';
import 'widgets/settings_ui_components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.openManualLocationCard = false});

  /// Optional shortcut to open Prayer & Location settings immediately.
  final bool openManualLocationCard;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _introController;
  bool _hasPin = AppSecurity.hasPinSet();

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..forward();

    if (widget.openManualLocationCard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pushPage(const PrayerLocationSettingsPage());
      });
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  void _pushPage(Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => page),
    );
  }

  String _locationSummary(AppSettings settings) {
    final loc = settings.prayerLocationMode == PrayerLocationMode.manual
        ? (settings.manualLocationLabel ?? 'يدوي')
        : 'GPS تلقائي';
    return '$loc • ${prayerMethodShortLabel(settings.prayerMethod)}';
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const FrostedSettingsSliverAppBar(
            title: 'الإعدادات',
            large: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),
                _StaggeredEntrance(
                  controller: _introController,
                  intervalStart: 0.0,
                  child: _AccountHeaderCard(
                    onTap: () => _pushPage(const SyncBackupSettingsPage()),
                  ),
                ),
                _StaggeredEntrance(
                  controller: _introController,
                  intervalStart: 0.12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SettingsSectionHeader(title: 'المظهر والواجهة'),
                      SettingsGroupCard(
                        dividerIndent: 16,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: AnimatedSegmentedControl<AppThemeMode>(
                              options: const [
                                SegmentOption(
                                  value: AppThemeMode.light,
                                  label: 'فاتح',
                                  icon: Icons.light_mode_rounded,
                                ),
                                SegmentOption(
                                  value: AppThemeMode.dark,
                                  label: 'داكن',
                                  icon: Icons.dark_mode_rounded,
                                ),
                                SegmentOption(
                                  value: AppThemeMode.system,
                                  label: 'تلقائي',
                                  icon: Icons.brightness_auto_rounded,
                                ),
                              ],
                              selected: settings.themeMode,
                              onChanged: (mode) async {
                                await ref
                                    .read(settingsProvider.notifier)
                                    .updateSettings(
                                      settings.copyWith(themeMode: mode),
                                    );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StaggeredEntrance(
                  controller: _introController,
                  intervalStart: 0.24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SettingsSectionHeader(title: 'الصلاة والتنبيهات'),
                      SettingsGroupCard(
                        children: [
                          SettingsNavTile(
                            icon: Icons.mosque_rounded,
                            iconColor: const Color(0xFF1F6F4A),
                            title: 'الموقع وطريقة الحساب',
                            subtitle: _locationSummary(settings),
                            onTap: () =>
                                _pushPage(const PrayerLocationSettingsPage()),
                          ),
                          SettingsNavTile(
                            icon: Icons.notifications_active_rounded,
                            iconColor: const Color(0xFFFF3B30),
                            title: 'الإشعارات ومواقيت التركيز',
                            subtitle: settings.focusModeEnabled
                                ? 'وضع الهدوء قبل الصلاة بـ ${settings.focusLeadMinutes} د'
                                : 'تنبيهات الأذان ومدة الصلاة',
                            trailingWidget: SettingsStatusPill(
                              label: settings.notificationsEnabled
                                  ? 'مفعّلة'
                                  : 'متوقفة',
                              color: settings.notificationsEnabled
                                  ? const Color(0xFF34C759)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                            ),
                            onTap: () => _pushPage(
                              const NotificationsTimingSettingsPage(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StaggeredEntrance(
                  controller: _introController,
                  intervalStart: 0.36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SettingsSectionHeader(title: 'البيانات والأمان'),
                      SettingsGroupCard(
                        children: [
                          SettingsNavTile(
                            icon: Icons.cloud_sync_rounded,
                            iconColor: const Color(0xFF007AFF),
                            title: 'المزامنة والنسخ الاحتياطي',
                            subtitle: 'سحابة Google وملفات JSON',
                            onTap: () =>
                                _pushPage(const SyncBackupSettingsPage()),
                          ),
                          SettingsNavTile(
                            icon: Icons.lock_rounded,
                            iconColor: const Color(0xFF5856D6),
                            title: 'قفل التطبيق برمز مرور',
                            subtitle: 'حماية بياناتك برمز من 4 أرقام',
                            trailingWidget: SettingsStatusPill(
                              label: _hasPin ? 'مفعّل' : 'غير مفعّل',
                              color: _hasPin
                                  ? const Color(0xFF34C759)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                            ),
                            onTap: () async {
                              await showAppLockSheet(context);
                              if (mounted) {
                                setState(
                                  () => _hasPin = AppSecurity.hasPinSet(),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StaggeredEntrance(
                  controller: _introController,
                  intervalStart: 0.48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SettingsSectionHeader(title: 'حول التطبيق'),
                      SettingsGroupCard(
                        children: [
                          SettingsNavTile(
                            icon: Icons.info_rounded,
                            iconColor: const Color(0xFF8E8E93),
                            title: 'عن تطبيق الرباط',
                            subtitle: 'الفكرة، الخصوصية، والدعم',
                            onTap: () => _pushPage(const AboutAppScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeaderCard extends StatelessWidget {
  const _AccountHeaderCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<User?>(
      stream: CloudSyncService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final signedIn = user != null;
        return SettingsGroupCard(
          dividerIndent: 16,
          children: [
            PressableScale(
              onTap: onTap,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: signedIn
                                ? [
                                    theme.colorScheme.primary,
                                    Color.lerp(
                                          theme.colorScheme.primary,
                                          Colors.black,
                                          0.2,
                                        ) ??
                                        theme.colorScheme.primary,
                                  ]
                                : [
                                    const Color(0xFF007AFF),
                                    const Color(0xFF0051B5),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (signedIn
                                      ? theme.colorScheme.primary
                                      : const Color(0xFF007AFF))
                                  .withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          signedIn
                              ? Icons.cloud_done_rounded
                              : Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              signedIn
                                  ? (user.displayName ?? 'حساب Google')
                                  : 'الرباط — الحفظ المحلي',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              signedIn
                                  ? (user.email ?? 'المزامنة السحابية متصلة')
                                  : AppStartup.isFirebaseReady
                                      ? 'اضغط لربط حساب Google والمزامنة'
                                      : 'النسخ الاحتياطي المحلي (JSON) متاح',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_left_rounded,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StaggeredEntrance extends StatelessWidget {
  const _StaggeredEntrance({
    required this.controller,
    required this.intervalStart,
    required this.child,
  });

  final AnimationController controller;
  final double intervalStart;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final end = (intervalStart + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }
}
