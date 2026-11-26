import 'dart:convert';

import '../domain/app_settings.dart';

T _parseEnum<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
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
    super.asrMadhab = AsrMadhab.shafi,
    super.phasePromptsEnabled = true,
    super.biometricLockEnabled = true,
    super.autoLockTimeoutSeconds = 15,
    super.manualLatitude,
    super.manualLongitude,
    super.manualLocationLabel,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      themeMode: settings.themeMode,
      prayerMethod: settings.prayerMethod,
      asrMadhab: settings.asrMadhab,
      notificationsEnabled: settings.notificationsEnabled,
      focusModeEnabled: settings.focusModeEnabled,
      phasePromptsEnabled: settings.phasePromptsEnabled,
      focusLeadMinutes: settings.focusLeadMinutes,
      prayerSlotDurationMinutes: settings.prayerSlotDurationMinutes,
      prayerLocationMode: settings.prayerLocationMode,
      biometricLockEnabled: settings.biometricLockEnabled,
      autoLockTimeoutSeconds: settings.autoLockTimeoutSeconds,
      manualLatitude: settings.manualLatitude,
      manualLongitude: settings.manualLongitude,
      manualLocationLabel: settings.manualLocationLabel,
    );
  }

  factory AppSettingsModel.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    const defaults = AppSettings.defaults;
    return AppSettingsModel(
      themeMode: _parseEnum(
        AppThemeMode.values,
        json['themeMode'] as String?,
        defaults.themeMode,
      ),
      prayerMethod: _parseEnum(
        PrayerCalculationMethod.values,
        json['prayerMethod'] as String?,
        defaults.prayerMethod,
      ),
      asrMadhab: _parseEnum(
        AsrMadhab.values,
        json['asrMadhab'] as String?,
        defaults.asrMadhab,
      ),
      notificationsEnabled:
          json['notificationsEnabled'] as bool? ?? defaults.notificationsEnabled,
      focusModeEnabled:
          json['focusModeEnabled'] as bool? ?? defaults.focusModeEnabled,
      phasePromptsEnabled:
          json['phasePromptsEnabled'] as bool? ?? defaults.phasePromptsEnabled,
      focusLeadMinutes:
          json['focusLeadMinutes'] as int? ?? defaults.focusLeadMinutes,
      prayerSlotDurationMinutes: json['prayerSlotDurationMinutes'] as int? ??
          defaults.prayerSlotDurationMinutes,
      prayerLocationMode: _parseEnum(
        PrayerLocationMode.values,
        json['prayerLocationMode'] as String?,
        defaults.prayerLocationMode,
      ),
      biometricLockEnabled: json['biometricLockEnabled'] as bool? ??
          defaults.biometricLockEnabled,
      autoLockTimeoutSeconds: json['autoLockTimeoutSeconds'] as int? ??
          defaults.autoLockTimeoutSeconds,
      manualLatitude: (json['manualLatitude'] as num?)?.toDouble(),
      manualLongitude: (json['manualLongitude'] as num?)?.toDouble(),
      manualLocationLabel: json['manualLocationLabel'] as String?,
    );
  }

  String toJson() {
    return jsonEncode({
      'themeMode': themeMode.name,
      'prayerMethod': prayerMethod.name,
      'asrMadhab': asrMadhab.name,
      'notificationsEnabled': notificationsEnabled,
      'focusModeEnabled': focusModeEnabled,
      'phasePromptsEnabled': phasePromptsEnabled,
      'focusLeadMinutes': focusLeadMinutes,
      'prayerSlotDurationMinutes': prayerSlotDurationMinutes,
      'prayerLocationMode': prayerLocationMode.name,
      'biometricLockEnabled': biometricLockEnabled,
      'autoLockTimeoutSeconds': autoLockTimeoutSeconds,
      'manualLatitude': manualLatitude,
      'manualLongitude': manualLongitude,
      'manualLocationLabel': manualLocationLabel,
    });
  }
}
