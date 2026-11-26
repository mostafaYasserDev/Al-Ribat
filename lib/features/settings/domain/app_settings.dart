enum AppThemeMode { dark, light, system }

enum PrayerCalculationMethod {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
}

enum AsrMadhab { shafi, hanafi }

/// Automatic: GPS. Manual: coordinates from location search (geocoding).
enum PrayerLocationMode { automatic, manual }

class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.prayerMethod,
    required this.notificationsEnabled,
    required this.focusModeEnabled,
    required this.focusLeadMinutes,
    required this.prayerSlotDurationMinutes,
    required this.prayerLocationMode,
    this.asrMadhab = AsrMadhab.shafi,
    this.phasePromptsEnabled = true,
    this.biometricLockEnabled = true,
    this.autoLockTimeoutSeconds = 15,
    this.manualLatitude,
    this.manualLongitude,
    this.manualLocationLabel,
  });

  final AppThemeMode themeMode;
  final PrayerCalculationMethod prayerMethod;
  final AsrMadhab asrMadhab;
  final bool notificationsEnabled;
  final bool focusModeEnabled;
  final bool phasePromptsEnabled;
  final int focusLeadMinutes;

  /// Estimated duration of prayer (default one third of an hour = 20 minutes).
  final int prayerSlotDurationMinutes;

  final PrayerLocationMode prayerLocationMode;
  final bool biometricLockEnabled;
  final int autoLockTimeoutSeconds;
  final double? manualLatitude;
  final double? manualLongitude;
  final String? manualLocationLabel;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    PrayerCalculationMethod? prayerMethod,
    AsrMadhab? asrMadhab,
    bool? notificationsEnabled,
    bool? focusModeEnabled,
    bool? phasePromptsEnabled,
    int? focusLeadMinutes,
    int? prayerSlotDurationMinutes,
    PrayerLocationMode? prayerLocationMode,
    bool? biometricLockEnabled,
    int? autoLockTimeoutSeconds,
    double? manualLatitude,
    double? manualLongitude,
    String? manualLocationLabel,
    bool clearManualLocation = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      asrMadhab: asrMadhab ?? this.asrMadhab,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      phasePromptsEnabled: phasePromptsEnabled ?? this.phasePromptsEnabled,
      focusLeadMinutes: focusLeadMinutes ?? this.focusLeadMinutes,
      prayerSlotDurationMinutes:
          prayerSlotDurationMinutes ?? this.prayerSlotDurationMinutes,
      prayerLocationMode: prayerLocationMode ?? this.prayerLocationMode,
      biometricLockEnabled: biometricLockEnabled ?? this.biometricLockEnabled,
      autoLockTimeoutSeconds:
          autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      manualLatitude:
          clearManualLocation ? null : (manualLatitude ?? this.manualLatitude),
      manualLongitude: clearManualLocation
          ? null
          : (manualLongitude ?? this.manualLongitude),
      manualLocationLabel: clearManualLocation
          ? null
          : (manualLocationLabel ?? this.manualLocationLabel),
    );
  }

  static const defaults = AppSettings(
    themeMode: AppThemeMode.light,
    prayerMethod: PrayerCalculationMethod.muslimWorldLeague,
    asrMadhab: AsrMadhab.shafi,
    notificationsEnabled: false,
    focusModeEnabled: true,
    phasePromptsEnabled: true,
    focusLeadMinutes: 15,
    prayerSlotDurationMinutes: 20,
    prayerLocationMode: PrayerLocationMode.automatic,
    biometricLockEnabled: true,
    autoLockTimeoutSeconds: 15,
    manualLatitude: null,
    manualLongitude: null,
    manualLocationLabel: null,
  );
}
