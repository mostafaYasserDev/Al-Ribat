enum AppThemeMode { dark, light, system }

enum PrayerCalculationMethod {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
}

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
    this.manualLatitude,
    this.manualLongitude,
    this.manualLocationLabel,
  });

  final AppThemeMode themeMode;
  final PrayerCalculationMethod prayerMethod;
  final bool notificationsEnabled;
  final bool focusModeEnabled;
  final int focusLeadMinutes;

  /// Estimated duration of prayer (default one third of an hour = 20 minutes).
  final int prayerSlotDurationMinutes;

  final PrayerLocationMode prayerLocationMode;
  final double? manualLatitude;
  final double? manualLongitude;
  final String? manualLocationLabel;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    PrayerCalculationMethod? prayerMethod,
    bool? notificationsEnabled,
    bool? focusModeEnabled,
    int? focusLeadMinutes,
    int? prayerSlotDurationMinutes,
    PrayerLocationMode? prayerLocationMode,
    double? manualLatitude,
    double? manualLongitude,
    String? manualLocationLabel,
    bool clearManualLocation = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      focusModeEnabled: focusModeEnabled ?? this.focusModeEnabled,
      focusLeadMinutes: focusLeadMinutes ?? this.focusLeadMinutes,
      prayerSlotDurationMinutes:
          prayerSlotDurationMinutes ?? this.prayerSlotDurationMinutes,
      prayerLocationMode: prayerLocationMode ?? this.prayerLocationMode,
      manualLatitude: clearManualLocation ? null : (manualLatitude ?? this.manualLatitude),
      manualLongitude: clearManualLocation ? null : (manualLongitude ?? this.manualLongitude),
      manualLocationLabel:
          clearManualLocation ? null : (manualLocationLabel ?? this.manualLocationLabel),
    );
  }

  static const defaults = AppSettings(
    themeMode: AppThemeMode.light,
    prayerMethod: PrayerCalculationMethod.muslimWorldLeague,
    notificationsEnabled: true,
    focusModeEnabled: true,
    focusLeadMinutes: 15,
    prayerSlotDurationMinutes: 20,
    prayerLocationMode: PrayerLocationMode.automatic,
    manualLatitude: null,
    manualLongitude: null,
    manualLocationLabel: null,
  );
}
