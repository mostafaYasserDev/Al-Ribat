import 'dart:convert';

import '../../domain/entities/app_settings.dart';

PrayerLocationMode _parseLocationMode(String? name) {
  for (final v in PrayerLocationMode.values) {
    if (v.name == name) return v;
  }
  return PrayerLocationMode.automatic;
}

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.themeMode,
    required super.prayerMethod,
    required super.notificationsEnabled,
    required super.focusModeEnabled,
    required super.focusLeadMinutes,
    required super.prayerSlotDurationMinutes,
    required super.prayerLocationMode,
    super.manualLatitude,
    super.manualLongitude,
    super.manualLocationLabel,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      themeMode: settings.themeMode,
      prayerMethod: settings.prayerMethod,
      notificationsEnabled: settings.notificationsEnabled,
      focusModeEnabled: settings.focusModeEnabled,
      focusLeadMinutes: settings.focusLeadMinutes,
      prayerSlotDurationMinutes: settings.prayerSlotDurationMinutes,
      prayerLocationMode: settings.prayerLocationMode,
      manualLatitude: settings.manualLatitude,
      manualLongitude: settings.manualLongitude,
      manualLocationLabel: settings.manualLocationLabel,
    );
  }

  factory AppSettingsModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return AppSettingsModel(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == (json['themeMode'] as String? ?? AppThemeMode.dark.name),
      ),
      prayerMethod: PrayerCalculationMethod.values.firstWhere(
        (e) =>
            e.name ==
            (json['prayerMethod'] as String? ??
                PrayerCalculationMethod.muslimWorldLeague.name),
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      focusModeEnabled: json['focusModeEnabled'] as bool? ?? true,
      focusLeadMinutes: json['focusLeadMinutes'] as int? ?? 15,
      prayerSlotDurationMinutes: json['prayerSlotDurationMinutes'] as int? ?? 20,
      prayerLocationMode: _parseLocationMode(json['prayerLocationMode'] as String?),
      manualLatitude: (json['manualLatitude'] as num?)?.toDouble(),
      manualLongitude: (json['manualLongitude'] as num?)?.toDouble(),
      manualLocationLabel: json['manualLocationLabel'] as String?,
    );
  }

  String toJson() {
    return jsonEncode({
      'themeMode': themeMode.name,
      'prayerMethod': prayerMethod.name,
      'notificationsEnabled': notificationsEnabled,
      'focusModeEnabled': focusModeEnabled,
      'focusLeadMinutes': focusLeadMinutes,
      'prayerSlotDurationMinutes': prayerSlotDurationMinutes,
      'prayerLocationMode': prayerLocationMode.name,
      'manualLatitude': manualLatitude,
      'manualLongitude': manualLongitude,
      'manualLocationLabel': manualLocationLabel,
    });
  }
}
