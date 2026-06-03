import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../application/providers.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../../services/app_permissions.dart';
import '../../services/backup_export_service.dart';
import 'developer_support_screen.dart';
import 'about_app_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

// RadioListTile: استخدام groupValue/onChanged ما زال الأساس في القنوات المستقرة؛ التحذير من RadioGroup قيد التطور.
// ignore_for_file: deprecated_member_use

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.openManualLocationCard = false});

  /// بعد اختيار «يدوي» في أول تشغيل: التمرير إلى بطاقة البحث اليدوي.
  final bool openManualLocationCard;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  final _manualSectionKey = GlobalKey();
  bool _searching = false;
  List<Location> _addressResults = const [];

  @override
  void initState() {
    super.initState();
    if (widget.openManualLocationCard) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        final ctx = _manualSectionKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        await Scrollable.ensureVisible(ctx, alignment: 0.05, duration: const Duration(milliseconds: 400));
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _refineLabel(Location loc, String query) async {
    try {
      final pm = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (pm.isEmpty) return query;
      final p = pm.first;
      final parts = <String>[
        if (p.locality != null && p.locality!.trim().isNotEmpty) p.locality!,
        if (p.subAdministrativeArea != null && p.subAdministrativeArea!.trim().isNotEmpty)
          p.subAdministrativeArea!,
        if (p.country != null && p.country!.trim().isNotEmpty) p.country!,
      ];
      if (parts.isNotEmpty) return parts.join('، ');
    } catch (_) {}
    return query;
  }

  Future<void> _applyLocation(Location loc, AppSettings settings, String query) async {
    final label = await _refineLabel(loc, query);
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(
            prayerLocationMode: PrayerLocationMode.manual,
            manualLatitude: loc.latitude,
            manualLongitude: loc.longitude,
            manualLocationLabel: label,
          ),
        );
    if (mounted) {
      setState(() => _addressResults = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم ضبط الموقع: $label')),
      );
    }
  }

  Future<void> _runSearch(AppSettings settings) async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await locationFromAddress(q);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _addressResults = const []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يُعثر على موقع. جرّب مدينة، حي، أو دولة.')),
        );
        return;
      }
      setState(() => _addressResults = results);
    } catch (e) {
      if (mounted) {
        setState(() => _addressResults = const []);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل البحث: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.favorite_outline, color: Theme.of(context).colorScheme.primary),
              title: const Text('دعم المطوّر'),
              subtitle: const Text('نبذة، صورة، روابط التبرع والتواصل'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Directionality(
                      textDirection: TextDirection.rtl,
                      child: DeveloperSupportScreen(),
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
              title: const Text('عن التطبيق'),
              subtitle: const Text('فكرة التطبيق وسياسة الخصوصية'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Directionality(
                      textDirection: TextDirection.rtl,
                      child: AboutAppScreen(),
                    ),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
              title: const Text('قفل التطبيق برمز مرور'),
              subtitle: const Text('حماية بياناتك برمز PIN المكون من 4 أرقام'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () {
                HapticFeedback.lightImpact();
                _showAppLockDialog(context);
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: const Text('نسخ احتياطي (JSON)'),
              subtitle: const Text(
                'المهام، العادات، التأملات، الجلسات، وإعدادات التطبيق — احفظ الملف حيث تريد أو شاركه.',
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
                    appSnack(context, 'تعذر التصدير: $e');
                  }
                }
              },
            ),
          ),
          Card(
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
                      'سيتم استبدال المهام والعادات والتأملات والجلسات والإعدادات الحالية ببيانات الملف.',
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
                  if (context.mounted) {
                    appSnack(context, 'تم الاستيراد بنجاح.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    appSnack(context, 'تعذر الاستيراد: $e');
                  }
                }
              },
            ),
          ),
          Card(
            child: SwitchListTile(
              value: settings.notificationsEnabled,
              title: const Text('تفعيل الإشعارات'),
              onChanged: (value) async {
                HapticFeedback.selectionClick();
                if (value) {
                  await AppPermissions.requestNotificationIfNeeded();
                  await AppPermissions.requestExactAlarmIfNeeded();
                  await AppPermissions.requestIgnoreBatteryOptimizationsIfNeeded();
                }
                await ref.read(settingsProvider.notifier).updateSettings(
                      settings.copyWith(notificationsEnabled: value),
                    );
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('إذن التنبيه في الوقت المحدد (أندرويد)'),
              subtitle: const Text(
                'إذا ظهرت رسالة «Exact alarms not permitted»، افتح إعدادات التطبيق واسمح بالتنبيهات الدقيقة.',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => openAppSettings(),
            ),
          ),
          Card(
            child: SwitchListTile(
              value: settings.focusModeEnabled,
              title: const Text('وضع الهدوء قبل الصلاة'),
              subtitle: const Text('تنبيه للاستعداد الذهني قبل وقت الصلاة'),
              onChanged: (value) async {
                await ref.read(settingsProvider.notifier).updateSettings(
                      settings.copyWith(focusModeEnabled: value),
                    );
              },
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('دقائق التنبيه قبل الصلاة'),
              subtitle: Slider(
                value: settings.focusLeadMinutes.toDouble(),
                min: 5,
                max: 25,
                divisions: 4,
                label: '${settings.focusLeadMinutes}',
                onChanged: (value) async {
                  await ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(focusLeadMinutes: value.round()),
                      );
                },
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('الوقت الافتراضي لمرحلة الصلاة'),
              subtitle: Text(
                'يُستخدم لتنبيه «بعد الصلاة» الافتراضي (${settings.prayerSlotDurationMinutes} دقيقة — ثلث ساعة ≈ ٢٠ دقيقة كبداية).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('تعديل مدة الصلاة (بالدقائق)'),
              subtitle: Slider(
                value: settings.prayerSlotDurationMinutes.toDouble(),
                min: 10,
                max: 45,
                divisions: 35,
                label: '${settings.prayerSlotDurationMinutes}',
                onChanged: (value) async {
                  await ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(prayerSlotDurationMinutes: value.round()),
                      );
                },
              ),
            ),
          ),
          Card(
            key: _manualSectionKey,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مصدر الموقع لحساب الأذان',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<PrayerLocationMode>(
                    value: PrayerLocationMode.automatic,
                    groupValue: settings.prayerLocationMode,
                    title: const Text('تلقائي (GPS)'),
                    subtitle: const Text('يطلب إذن الموقع ويحدّث الأوقات تلقائياً'),
                    onChanged: (v) async {
                      if (v == null) return;
                      var permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                      }
                      if (permission == LocationPermission.deniedForever) {
                        if (context.mounted) {
                          appSnack(
                            context,
                            'صلاحية الموقع مرفوضة دائماً. افتح إعدادات التطبيق لتفعيلها.',
                          );
                        }
                        return;
                      }
                      if (permission == LocationPermission.denied) {
                        if (context.mounted) {
                          appSnack(context, 'لم يتم منح صلاحية الموقع.');
                        }
                        return;
                      }
                      await ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(prayerLocationMode: v),
                          );
                    },
                  ),
                  RadioListTile<PrayerLocationMode>(
                    value: PrayerLocationMode.manual,
                    groupValue: settings.prayerLocationMode,
                    title: const Text('يدوي (بحث عن مكان)'),
                    subtitle: const Text('ابحث عن مدينة أو حي لتثبيت الإحداثيات'),
                    onChanged: (v) async {
                      if (v == null) return;
                      await ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(prayerLocationMode: v),
                          );
                    },
                  ),
                  if (settings.prayerLocationMode == PrayerLocationMode.manual) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'بحث (مثال: الرباط، المغرب)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _searching ? null : () => _runSearch(settings),
                      icon: _searching
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_searching ? 'جاري البحث…' : 'بحث عن نتائج'),
                    ),
                    if (_addressResults.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'اختر النتيجة الأدق (عدة اقتراحات من الخادم):',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      ..._addressResults.asMap().entries.map((e) {
                        final loc = e.value;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
                          ),
                          subtitle: Text('اقتراح ${e.key + 1}'),
                          onTap: () => _applyLocation(loc, settings, _searchController.text.trim()),
                        );
                      }),
                    ],
                    if (settings.manualLocationLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'المختار: ${settings.manualLocationLabel}\n'
                          '${settings.manualLatitude?.toStringAsFixed(4)}, '
                          '${settings.manualLongitude?.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('طريقة الحساب الفقهي'),
              subtitle: Text(_labelMethod(settings.prayerMethod)),
              trailing: DropdownButton<PrayerCalculationMethod>(
                value: settings.prayerMethod,
                onChanged: (value) async {
                  if (value == null) return;
                  await ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(prayerMethod: value),
                      );
                },
                items: PrayerCalculationMethod.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(_labelMethod(e)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('المظهر'),
              trailing: DropdownButton<AppThemeMode>(
                value: settings.themeMode,
                onChanged: (value) async {
                  if (value == null) return;
                  await ref.read(settingsProvider.notifier).updateSettings(
                        settings.copyWith(themeMode: value),
                      );
                },
                items: const [
                  DropdownMenuItem(value: AppThemeMode.dark, child: Text('داكن')),
                  DropdownMenuItem(value: AppThemeMode.light, child: Text('فاتح')),
                  DropdownMenuItem(value: AppThemeMode.system, child: Text('تلقائي')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelMethod(PrayerCalculationMethod method) {
    switch (method) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return 'رابطة العالم الإسلامي';
      case PrayerCalculationMethod.egyptian:
        return 'الهيئة المصرية';
      case PrayerCalculationMethod.karachi:
        return 'كراتشي';
      case PrayerCalculationMethod.ummAlQura:
        return 'أم القرى';
      case PrayerCalculationMethod.dubai:
        return 'دبي';
    }
  }

  void _showAppLockDialog(BuildContext context) {
    final box = Hive.box<String>('meta_box');
    final currentPin = box.get('app_pin');
    final controller = TextEditingController(text: currentPin);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('رمز مرور التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('أدخل 4 أرقام لقفل التطبيق، أو اتركه فارغاً لإلغاء القفل.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'مثال: 1234',
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final pin = controller.text.trim();
              if (pin.isEmpty) {
                await box.delete('app_pin');
                if (context.mounted) {
                  appSnack(context, 'تم إلغاء قفل التطبيق.');
                  Navigator.pop(ctx);
                }
              } else if (pin.length == 4 && int.tryParse(pin) != null) {
                await box.put('app_pin', pin);
                if (context.mounted) {
                  appSnack(context, 'تم تعيين رمز المرور بنجاح.');
                  Navigator.pop(ctx);
                }
              } else {
                appSnack(context, 'يجب أن يكون الرمز 4 أرقام فقط.');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
