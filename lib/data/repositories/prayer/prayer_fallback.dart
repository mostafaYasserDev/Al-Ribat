part of '../prayer_repository_impl.dart';

List<PrayerTime> _fallbackPrayerForDate(DateTime date) {
  return [
    PrayerTime(
      phase: PrayerPhase.fajr,
      time: DateTime(date.year, date.month, date.day, 5, 0),
    ),
    PrayerTime(
      phase: PrayerPhase.dhuhr,
      time: DateTime(date.year, date.month, date.day, 12, 30),
    ),
    PrayerTime(
      phase: PrayerPhase.asr,
      time: DateTime(date.year, date.month, date.day, 16, 0),
    ),
    PrayerTime(
      phase: PrayerPhase.maghrib,
      time: DateTime(date.year, date.month, date.day, 18, 45),
    ),
    PrayerTime(
      phase: PrayerPhase.isha,
      time: DateTime(date.year, date.month, date.day, 20, 15),
    ),
  ];
}
