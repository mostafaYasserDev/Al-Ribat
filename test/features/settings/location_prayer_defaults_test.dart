import 'package:al_ribat/domain/entities/app_settings.dart';
import 'package:al_ribat/features/prayer/domain/location_prayer_defaults.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('infers Egyptian method and Shafi madhab for Egypt', () {
    final byLabel = LocationPrayerDefaults.infer(locationLabel: 'القاهرة، مصر');
    expect(byLabel.method, PrayerCalculationMethod.egyptian);
    expect(byLabel.madhab, AsrMadhab.shafi);

    final byCoords = LocationPrayerDefaults.infer(
      latitude: 30.0444,
      longitude: 31.2357,
    );
    expect(byCoords.method, PrayerCalculationMethod.egyptian);
    expect(byCoords.madhab, AsrMadhab.shafi);
  });

  test('infers Umm Al-Qura for Saudi Arabia and Dubai for UAE', () {
    final ksa = LocationPrayerDefaults.infer(locationLabel: 'مكة المكرمة');
    expect(ksa.method, PrayerCalculationMethod.ummAlQura);
    expect(ksa.madhab, AsrMadhab.shafi);

    final uae = LocationPrayerDefaults.infer(locationLabel: 'دبي، الإمارات');
    expect(uae.method, PrayerCalculationMethod.dubai);
    expect(uae.madhab, AsrMadhab.shafi);
  });

  test('infers Karachi and Hanafi madhab for Pakistan/India', () {
    final pk = LocationPrayerDefaults.infer(locationLabel: 'Karachi, Pakistan');
    expect(pk.method, PrayerCalculationMethod.karachi);
    expect(pk.madhab, AsrMadhab.hanafi);
  });

  test('falls back to Muslim World League and Shafi for other regions', () {
    final uk = LocationPrayerDefaults.infer(
      locationLabel: 'London, UK',
      latitude: 51.5072,
      longitude: -0.1276,
    );
    expect(uk.method, PrayerCalculationMethod.muslimWorldLeague);
    expect(uk.madhab, AsrMadhab.shafi);
  });
}
