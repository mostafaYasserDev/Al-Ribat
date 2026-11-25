import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../application/providers.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../services/app_permissions.dart';
import '../widgets/settings_ui_components.dart';

class NotificationsTimingSettingsPage extends ConsumerWidget {
  const NotificationsTimingSettingsPage({super.key});

  static const _leadOptions = [5, 10, 15, 20, 25];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final theme = Theme.of(context);
    final showAndroidAlarm = !kIsWeb && Platform.isAndroid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const FrostedSettingsSliverAppBar(
              title: 'الإشعارات ومواقيت التركيز',
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SettingsSectionHeader(
                    title: 'التنبيهات',
                    padding: EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
                  ),
                  SettingsGroupCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFFF3B30),
                        title: 'تفعيل الإشعارات',
                        subtitle: 'تنبيهات الأذان والأنشطة المرتبطة بالصلاة',
                        value: settings.notificationsEnabled,
                        onChanged: (value) async {
                          if (value) {
                            await AppPermissions.requestNotificationIfNeeded();
                            await AppPermissions.requestExactAlarmIfNeeded();
                            await AppPermissions
                                .requestIgnoreBatteryOptimizationsIfNeeded();
                          }
                          await ref
                              .read(settingsProvider.notifier)
                              .updateSettings(
                                settings.copyWith(notificationsEnabled: value),
                              );
                        },
                      ),
                      if (showAndroidAlarm)
                        SettingsNavTile(
                          icon: Icons.alarm_on_rounded,
                          iconColor: const Color(0xFFFF9500),
                          title: 'إذن التنبيه في الوقت المحدد',
                          subtitle: 'لضمان وصول تنبيهات الأذان بدقة في أندرويد',
                          onTap: () => openAppSettings(),
                        ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'الاستعداد قبل الصلاة'),
                  SettingsGroupCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.self_improvement_rounded,
                        iconColor: const Color(0xFF5856D6),
                        title: 'وضع الهدوء قبل الصلاة',
                        subtitle: 'تنبيه للاستعداد الذهني قبل دخول الوقت',
                        value: settings.focusModeEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(settingsProvider.notifier)
                              .updateSettings(
                                settings.copyWith(focusModeEnabled: value),
                              );
                        },
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: settings.focusModeEnabled
                            ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'التنبيه قبل الصلاة بـ',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SettingsStatusPill(
                                          label:
                                              '${settings.focusLeadMinutes} دقيقة',
                                          color: theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: _leadOptions.map((mins) {
                                        final selected =
                                            settings.focusLeadMinutes == mins;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                            ),
                                            child: GestureDetector(
                                              onTap: () async {
                                                if (selected) return;
                                                HapticFeedback.selectionClick();
                                                await ref
                                                    .read(settingsProvider
                                                        .notifier)
                                                    .updateSettings(
                                                      settings.copyWith(
                                                        focusLeadMinutes: mins,
                                                      ),
                                                    );
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 9,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? theme
                                                          .colorScheme.primary
                                                      : theme.colorScheme
                                                          .surfaceContainerHighest
                                                          .withValues(
                                                              alpha: 0.65),
                                                  borderRadius:
                                                      BorderRadius.circular(11),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$mins د',
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: selected
                                                          ? theme.colorScheme
                                                              .onPrimary
                                                          : theme.colorScheme
                                                              .onSurface,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(title: 'نافذة الصلاة'),
                  SettingsGroupCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const SettingsIconBadge(
                                  icon: Icons.timelapse_rounded,
                                  color: Color(0xFF007AFF),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'المدة الافتراضية للصلاة',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                ),
                                SettingsStatusPill(
                                  label:
                                      '${settings.prayerSlotDurationMinutes} دقيقة',
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 9,
                                ),
                              ),
                              child: Slider(
                                value: settings.prayerSlotDurationMinutes
                                    .toDouble(),
                                min: 10,
                                max: 45,
                                divisions: 35,
                                label:
                                    '${settings.prayerSlotDurationMinutes} دقيقة',
                                onChanged: (value) async {
                                  await ref
                                      .read(settingsProvider.notifier)
                                      .updateSettings(
                                        settings.copyWith(
                                          prayerSlotDurationMinutes:
                                              value.round(),
                                        ),
                                      );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SettingsSectionFooter(
                    text:
                        'تُستخدم هذه المدة لحساب تنبيهات «بعد الصلاة» للأنشطة المجدولة (الافتراضي ٢٠ دقيقة).',
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
