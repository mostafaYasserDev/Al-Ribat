part of '../prayer_repository_impl.dart';

class _PrayerDayData {
  const _PrayerDayData({required this.prayers, required this.sunrise});

  final List<PrayerTime> prayers;
  final DateTime sunrise;
}
