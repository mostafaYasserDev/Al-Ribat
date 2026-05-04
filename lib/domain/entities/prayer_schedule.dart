import 'prayer_time.dart';

/// Today's prayer row plus tomorrow's Fajr (for night gap until Fajr).
class PrayerSchedule {
  const PrayerSchedule({
    required this.today,
    required this.tomorrowFajr,
    required this.todaySunrise,
  });

  final List<PrayerTime> today;
  final PrayerTime tomorrowFajr;
  final DateTime todaySunrise;
}
