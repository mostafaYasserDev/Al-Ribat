import 'package:flutter_test/flutter_test.dart';
import 'package:al_ribat/features/prayer/prayer.dart';

void main() {
  group('PrayerPhase', () {
    test('Arabic names match Islamic convention', () {
      expect(PrayerPhase.fajr.arabicName, 'الفجر');
      expect(PrayerPhase.dhuhr.arabicName, 'الظهر');
      expect(PrayerPhase.asr.arabicName, 'العصر');
      expect(PrayerPhase.maghrib.arabicName, 'المغرب');
      expect(PrayerPhase.isha.arabicName, 'العشاء');
    });

    test('All phases provide light and dark gradients', () {
      for (final phase in PrayerPhase.values) {
        expect(phase.gradient.length, 2);
        expect(phase.lightGradient.length, 2);
      }
    });

    test('Phase by name lookup works correctly', () {
      expect(PrayerPhase.fromName('fajr'), PrayerPhase.fajr);
      expect(PrayerPhase.fromName('dhuhr'), PrayerPhase.dhuhr);
      expect(PrayerPhase.fromName('maghrib'), PrayerPhase.maghrib);
      expect(PrayerPhase.fromName('unknown'), isNull);
    });
  });

  group('PrayerSchedule', () {
    test('Fallback schedule produces valid 5 prayers and tomorrow Fajr', () {
      final now = DateTime(2026, 11, 24, 12, 0);
      final schedule = PrayerRepositoryImpl.fallbackSchedule(now);

      expect(schedule.today.length, 5);
      expect(schedule.today.map((p) => p.phase), [
        PrayerPhase.fajr,
        PrayerPhase.dhuhr,
        PrayerPhase.asr,
        PrayerPhase.maghrib,
        PrayerPhase.isha,
      ]);
      expect(schedule.tomorrowFajr.phase, PrayerPhase.fajr);
      expect(
        schedule.tomorrowFajr.time.isAfter(schedule.today.last.time),
        isTrue,
      );
    });
  });
}
