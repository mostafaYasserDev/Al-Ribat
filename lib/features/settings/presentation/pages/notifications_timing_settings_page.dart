import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../application/providers.dart';
import '../../../../core/ui_feedback.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../../services/app_permissions.dart';
import '../widgets/settings_ui_components.dart';

class NotificationsTimingSettingsPage extends ConsumerStatefulWidget {
  const NotificationsTimingSettingsPage({super.key});

  @override
  ConsumerState<NotificationsTimingSettingsPage> createState() =>
      _NotificationsTimingSettingsPageState();
}

class _NotificationsTimingSettingsPageState
    extends ConsumerState<NotificationsTimingSettingsPage>
    with WidgetsBindingObserver {
  static const _leadOptions = [5, 10, 15, 20, 25];

  double? _slotDurationDraft;
  bool? _notifGranted;
  bool? _exactAlarmGranted;
  bool? _batteryIgnored;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isNotificationsSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    if (!_isAndroid) return;
    try {
      final notif = await Permission.notification.isGranted;
      final alarm = await Permission.scheduleExactAlarm.isGranted;
      final battery = await Permission.ignoreBatteryOptimizations.isGranted;
      if (mounted) {
        setState(() {
          _notifGranted = notif;
          _exactAlarmGranted = alarm;
          _batteryIgnored = battery;
        });
      }
    } catch (_) {}
  }

  Future<void> _onNotificationsToggled(
    AppSettings settings,
    bool value,
  ) async {
    if (value && !_isNotificationsSupported) {
      appSnack(
        context,
        'التنبيهات المحلية مدعومة على أندرويد وiOS وmacOS فقط.',
      );
    }

    if (value && _isAndroid) {
      await AppPermissions.requestNotificationIfNeeded();
      await AppPermissions.requestExactAlarmIfNeeded();
      await AppPermissions.requestIgnoreBatteryOptimizationsIfNeeded();
      await _refreshPermissions();
      if (_notifGranted == false) {
        if (mounted) {
          appSnack(
            context,
            'يرجى منح إذن الإشعارات من إعدادات النظام لتفعيل التنبيهات.',
          );
        }
        return;
      }
    }

    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(notificationsEnabled: value),
        );
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final theme = Theme.of(context);
    final slotMinutes =
        (_slotDurationDraft ?? settings.prayerSlotDurationMinutes.toDouble())
            .round();

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
                        subtitle: _isNotificationsSupported
                            ? 'تنبيهات الأذان والأنشطة المرتبطة بالصلاة'
                            : 'متاح على أجهزة أندرويد وiOS وmacOS',
                        value: settings.notificationsEnabled,
                        onChanged: (value) =>
                            _onNotificationsToggled(settings, value),
                      ),
                      SettingsSwitchTile(
                        icon: Icons.task_alt_rounded,
                        iconColor: const Color(0xFF34C759),
                        title: 'تنبيهات مرحلة بعد الصلاة',
                        subtitle: 'تذكير باختيار نشاطك بعد انتهاء وقت الصلاة',
                        value: settings.phasePromptsEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(settingsProvider.notifier)
                              .updateSettings(
                                settings.copyWith(phasePromptsEnabled: value),
                              );
                        },
                      ),
                      if (_isAndroid) ...[
                        SettingsNavTile(
                          icon: Icons.alarm_on_rounded,
                          iconColor: const Color(0xFFFF9500),
                          title: 'إذن التنبيه في الوقت المحدد',
                          subtitle: 'لضمان وصول تنبيهات الأذان بدقة في أندرويد',
                          trailingWidget: _exactAlarmGranted == null
                              ? null
                              : SettingsStatusPill(
                                  label: _exactAlarmGranted!
                                      ? 'ممنوح'
                                      : 'يحتاج تفعيل',
                                  color: _exactAlarmGranted!
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFFFF9500),
                                ),
                          onTap: () async {
                            await openAppSettings();
                            await _refreshPermissions();
                          },
                        ),
                        SettingsNavTile(
                          icon: Icons.battery_saver_rounded,
                          iconColor: const Color(0xFF007AFF),
                          title: 'استثناء تحسين البطارية',
                          subtitle: 'يمنع النظام من إيقاف التنبيهات في الخلفية',
                          trailingWidget: _batteryIgnored == null
                              ? null
                              : SettingsStatusPill(
                                  label:
                                      _batteryIgnored! ? 'مفعّل' : 'غير مفعّل',
                                  color: _batteryIgnored!
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFFFF9500),
                                ),
                          onTap: () async {
                            await AppPermissions
                                .requestIgnoreBatteryOptimizationsIfNeeded();
                            await _refreshPermissions();
                          },
                        ),
                      ],
                    ],
                  ),
                  const SettingsSectionHeader(title: 'الاستعداد قبل الصلاة'),
                  SettingsGroupCard(
                    children: [
                      SettingsSwitchTile(
                        icon: Icons.self_improvement_rounded,
                        iconColor: const Color(0xFF5856D6),
                        title: 'وضع الهدوء قبل الصلاة',
                        subtitle: 'إرسال تنبيه للاستعداد الذهني قبل دخول الوقت',
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
                                  label: '$slotMinutes دقيقة',
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
                                value: slotMinutes.toDouble().clamp(10, 45),
                                min: 10,
                                max: 45,
                                divisions: 35,
                                label: '$slotMinutes دقيقة',
                                onChanged: (value) {
                                  setState(() => _slotDurationDraft = value);
                                },
                                onChangeEnd: (value) async {
                                  final rounded = value.round();
                                  setState(() => _slotDurationDraft = null);
                                  if (rounded ==
                                      settings.prayerSlotDurationMinutes) {
                                    return;
                                  }
                                  await ref
                                      .read(settingsProvider.notifier)
                                      .updateSettings(
                                        settings.copyWith(
                                          prayerSlotDurationMinutes: rounded,
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
