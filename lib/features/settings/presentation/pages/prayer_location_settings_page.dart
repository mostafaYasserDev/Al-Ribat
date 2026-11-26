import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../application/providers.dart';
import '../../../../core/errors/error_reporter.dart';
import '../../../../core/ui_feedback.dart';
import '../../../../domain/entities/app_settings.dart';
import '../../../prayer/data/location_search_service.dart';
import '../../../prayer/data/prayer_repository_impl.dart';
import '../../../prayer/domain/location_prayer_defaults.dart';
import '../../../prayer/presentation/widgets/manual_location_dialog.dart';
import '../widgets/settings_ui_components.dart';

String prayerMethodLabel(PrayerCalculationMethod method) {
  switch (method) {
    case PrayerCalculationMethod.muslimWorldLeague:
      return 'رابطة العالم الإسلامي';
    case PrayerCalculationMethod.egyptian:
      return 'الهيئة المصرية العامة للمساحة';
    case PrayerCalculationMethod.karachi:
      return 'جامعة العلوم الإسلامية بكراتشي';
    case PrayerCalculationMethod.ummAlQura:
      return 'أم القرى';
    case PrayerCalculationMethod.dubai:
      return 'دبي';
  }
}

String prayerMethodShortLabel(PrayerCalculationMethod method) {
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

class PrayerLocationSettingsPage extends ConsumerStatefulWidget {
  const PrayerLocationSettingsPage({super.key});

  @override
  ConsumerState<PrayerLocationSettingsPage> createState() =>
      _PrayerLocationSettingsPageState();
}

class _PrayerLocationSettingsPageState
    extends ConsumerState<PrayerLocationSettingsPage> {
  final _searchController = TextEditingController();
  bool _searching = false;
  List<LocationSearchResult> _addressResults = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onModeChanged(
    AppSettings settings,
    PrayerLocationMode mode,
  ) async {
    if (mode == PrayerLocationMode.manual) {
      await ref.read(settingsProvider.notifier).updateSettings(
            settings.copyWith(prayerLocationMode: mode),
          );
      return;
    }

    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (isMobile) {
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          if (mounted) {
            appSnack(
              context,
              'خدمة الموقع (GPS) مغلقة في الجهاز. فعّلها أو اختر الوضع اليدوي.',
            );
          }
          return;
        }
      } catch (e) {
        reportError('Settings location service check', e);
      }
    }

    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      reportError('Settings location permission', e);
      if (!isMobile) {
        await ref.read(settingsProvider.notifier).updateSettings(
              settings.copyWith(prayerLocationMode: mode),
            );
        if (mounted) {
          appSnack(context, 'تم تفعيل التحديد التلقائي التقريبي لسطح المكتب.');
        }
        return;
      }
      if (mounted) {
        appSnack(context, 'خدمة الموقع غير متاحة هنا، استخدم الوضع اليدوي.');
      }
      return;
    }

    if (isMobile && permission == LocationPermission.deniedForever) {
      if (mounted) {
        appSnack(
          context,
          'صلاحية الموقع مرفوضة دائماً. افتح إعدادات التطبيق لتفعيلها.',
        );
      }
      return;
    }
    if (isMobile && permission == LocationPermission.denied) {
      if (mounted) {
        appSnack(context, 'لم يتم منح صلاحية الموقع.');
      }
      return;
    }

    final cachedGps = PrayerRepositoryImpl.cachedGpsCoordinates();
    final updated = settings.copyWith(prayerLocationMode: mode);
    if (cachedGps != null) {
      final smart = LocationPrayerDefaults.infer(
        latitude: cachedGps.latitude,
        longitude: cachedGps.longitude,
      );
      await ref.read(settingsProvider.notifier).updateSettings(
            updated.copyWith(
              prayerMethod: smart.method,
              asrMadhab: smart.madhab,
            ),
          );
    } else {
      await ref.read(settingsProvider.notifier).updateSettings(updated);
    }
    ref.invalidate(prayerScheduleProvider);
  }

  Future<void> _refreshAutomaticLocation(AppSettings settings) async {
    ref.invalidate(prayerScheduleProvider);
    final schedule = await ref.read(prayerScheduleProvider.future);
    final cachedGps = PrayerRepositoryImpl.cachedGpsCoordinates();
    if (!mounted) return;
    if (cachedGps != null) {
      final smart = LocationPrayerDefaults.infer(
        latitude: cachedGps.latitude,
        longitude: cachedGps.longitude,
      );
      await ref.read(settingsProvider.notifier).updateSettings(
            settings.copyWith(
              prayerLocationMode: PrayerLocationMode.automatic,
              prayerMethod: smart.method,
              asrMadhab: smart.madhab,
            ),
          );
      if (mounted) {
        appSnack(
          context,
          'تم تحديث الموقع (${cachedGps.latitude.toStringAsFixed(2)}, ${cachedGps.longitude.toStringAsFixed(2)}) وضبط ${prayerMethodShortLabel(smart.method)}.',
        );
      }
    } else if (schedule.today.isNotEmpty) {
      appSnack(context, 'تم تحديث جدول المواقيت.');
    }
  }

  Future<void> _runSearch(AppSettings settings) async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await LocationSearchService.searchPlaces(q);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _addressResults = const []);
        appSnack(context, 'لم يُعثر على موقع. جرّب مدينة، حي، أو دولة.');
        return;
      }
      setState(() => _addressResults = results);
    } catch (e) {
      if (mounted) {
        setState(() => _addressResults = const []);
        appError(context, e, fallback: 'تعذر البحث عن الموقع. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _applyLocationResult(
    LocationSearchResult result,
    AppSettings settings,
  ) async {
    final label = result.fullLabel;
    final smart = LocationPrayerDefaults.infer(
      locationLabel: label,
      latitude: result.latitude,
      longitude: result.longitude,
    );
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(
            prayerLocationMode: PrayerLocationMode.manual,
            manualLatitude: result.latitude,
            manualLongitude: result.longitude,
            manualLocationLabel: label,
            prayerMethod: smart.method,
            asrMadhab: smart.madhab,
          ),
        );
    HapticFeedback.mediumImpact();
    if (mounted) {
      setState(() => _addressResults = const []);
      appSnack(
        context,
        'تم ضبط الموقع: $label • ${prayerMethodShortLabel(smart.method)}',
      );
    }
  }

  Future<void> _pickFromPopularDialog(AppSettings settings) async {
    final picked = await showManualLocationPickerDialog(context);
    if (picked == null || !mounted) return;
    final smart = LocationPrayerDefaults.infer(
      locationLabel: picked.$2,
      latitude: picked.$1.latitude,
      longitude: picked.$1.longitude,
    );
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(
            prayerLocationMode: PrayerLocationMode.manual,
            manualLatitude: picked.$1.latitude,
            manualLongitude: picked.$1.longitude,
            manualLocationLabel: picked.$2,
            prayerMethod: smart.method,
            asrMadhab: smart.madhab,
          ),
        );
    HapticFeedback.mediumImpact();
    if (mounted) {
      appSnack(
        context,
        'تم ضبط الموقع: ${picked.$2} • ${prayerMethodShortLabel(smart.method)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final theme = Theme.of(context);
    final isManual = settings.prayerLocationMode == PrayerLocationMode.manual;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const FrostedSettingsSliverAppBar(title: 'أوقات الصلاة والموقع'),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SettingsSectionHeader(
                    title: 'مصدر الموقع الجغرافي',
                    padding: EdgeInsetsDirectional.fromSTEB(20, 12, 20, 8),
                  ),
                  SettingsGroupCard(
                    dividerIndent: 16,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AnimatedSegmentedControl<PrayerLocationMode>(
                              options: const [
                                SegmentOption(
                                  value: PrayerLocationMode.automatic,
                                  label: 'تلقائي (GPS)',
                                  icon: Icons.my_location_rounded,
                                ),
                                SegmentOption(
                                  value: PrayerLocationMode.manual,
                                  label: 'تحديد يدوي',
                                  icon: Icons.travel_explore_rounded,
                                ),
                              ],
                              selected: settings.prayerLocationMode,
                              onChanged: (mode) =>
                                  _onModeChanged(settings, mode),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: isManual
                                  ? _buildManualLocationBody(theme, settings)
                                  : _buildAutomaticLocationBody(
                                      theme,
                                      settings,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SettingsSectionHeader(
                      title: 'المذهب الفقهي لصلاة العصر'),
                  SettingsGroupCard(
                    dividerIndent: 16,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: AnimatedSegmentedControl<AsrMadhab>(
                          options: const [
                            SegmentOption(
                              value: AsrMadhab.shafi,
                              label: 'الشافعي / الجمهور',
                            ),
                            SegmentOption(
                              value: AsrMadhab.hanafi,
                              label: 'الحنفي',
                            ),
                          ],
                          selected: settings.asrMadhab,
                          onChanged: (madhab) async {
                            await ref
                                .read(settingsProvider.notifier)
                                .updateSettings(
                                  settings.copyWith(asrMadhab: madhab),
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SettingsSectionFooter(
                    text:
                        'يؤثر المذهب الفقهي على وقت دخول صلاة العصر فقط (يتأخر قليلاً في المذهب الحنفي).',
                  ),
                  const SettingsSectionHeader(title: 'طريقة الحساب الفقهي'),
                  SettingsGroupCard(
                    dividerIndent: 20,
                    children: PrayerCalculationMethod.values.map((method) {
                      final selected = settings.prayerMethod == method;
                      return InkWell(
                        onTap: () async {
                          if (selected) return;
                          HapticFeedback.selectionClick();
                          await ref
                              .read(settingsProvider.notifier)
                              .updateSettings(
                                settings.copyWith(prayerMethod: method),
                              );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  prayerMethodLabel(method),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 15,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: selected
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        key: ValueKey(method),
                                        color: theme.colorScheme.primary,
                                        size: 22,
                                      )
                                    : const SizedBox(width: 22, height: 22),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SettingsSectionFooter(
                    text:
                        'تختلف طرق الحساب في زوايا الفجر والعشاء المعتمدة في كل بلد.',
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

  Widget _buildAutomaticLocationBody(ThemeData theme, AppSettings settings) {
    final cachedGps = PrayerRepositoryImpl.cachedGpsCoordinates();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.gps_fixed_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cachedGps != null
                      ? 'الإحداثيات الحالية: ${cachedGps.latitude.toStringAsFixed(3)}, ${cachedGps.longitude.toStringAsFixed(3)}'
                      : 'يتم تحديث المواقيت تلقائياً عند توفر الموقع أو عبر الشبكة.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: () => _refreshAutomaticLocation(settings),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('تحديث'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualLocationBody(ThemeData theme, AppSettings settings) {
    final hasManualCoords =
        settings.manualLatitude != null && settings.manualLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        if (!hasManualCoords) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'لم يتم تحديد مدينة بعد — يُستخدم التوقيت الافتراضي مؤقتاً. ابحث عن مدينتك أو اختر من المدن الشائعة.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ] else if (settings.manualLocationLabel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.manualLocationLabel!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (settings.manualLatitude != null &&
                          settings.manualLongitude != null)
                        Text(
                          '${settings.manualLatitude!.toStringAsFixed(4)}, ${settings.manualLongitude!.toStringAsFixed(4)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _runSearch(settings),
          decoration: InputDecoration(
            hintText: 'ابحث عن مدينة أو حي (مثال: أسيوط، مصر)',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _addressResults = const []);
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _searching ? null : () => _runSearch(settings),
                icon: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded, size: 18),
                label: Text(_searching ? 'جاري البحث…' : 'بحث'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _pickFromPopularDialog(settings),
              icon: const Icon(Icons.location_city_rounded, size: 18),
              label: const Text('مدن شائعة'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        if (_addressResults.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'اختر النتيجة المناسبة:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ..._addressResults.map((result) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.place_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                result.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                result.subtitle.isNotEmpty
                    ? result.subtitle
                    : '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
              ),
              onTap: () => _applyLocationResult(result, settings),
            );
          }),
        ],
      ],
    );
  }
}
