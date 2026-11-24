import 'package:al_ribat/domain/entities/app_settings.dart';
import 'prayer_schedule.dart';
import 'prayer_time.dart';

abstract class PrayerRepository {
  Future<List<PrayerTime>> getPrayerTimesForToday(
    AppSettings settings, {
    DateTime? date,
  });

  /// Full day row + next calendar day's Fajr (for gaps after Isha).
  Future<PrayerSchedule> getPrayerSchedule(
    AppSettings settings, {
    DateTime? date,
  });
}
