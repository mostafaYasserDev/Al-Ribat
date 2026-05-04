import '../entities/app_settings.dart';
import '../entities/prayer_schedule.dart';
import '../entities/prayer_time.dart';

abstract class PrayerRepository {
  Future<List<PrayerTime>> getPrayerTimesForToday(AppSettings settings);

  /// Full day row + next calendar day's Fajr (for gaps after Isha).
  Future<PrayerSchedule> getPrayerSchedule(AppSettings settings);
}
