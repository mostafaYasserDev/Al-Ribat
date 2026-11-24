import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:al_ribat/core/errors/error_reporter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/prayer_repository.dart';

part 'prayer/prayer_coordinates.dart';
part 'prayer/prayer_coordinates_cache.dart';
part 'prayer/prayer_computation.dart';
part 'prayer/prayer_fallback.dart';
part 'prayer/prayer_day_data.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  @override
  Future<List<PrayerTime>> getPrayerTimesForToday(
    AppSettings settings, {
    DateTime? date,
  }) async {
    final s = await getPrayerSchedule(settings, date: date);
    return s.today;
  }

  @override
  Future<PrayerSchedule> getPrayerSchedule(
    AppSettings settings, {
    DateTime? date,
  }) async {
    final coords = await _resolvePrayerCoordinates(settings);
    final now = date ?? DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (coords == null) {
      final t = _fallbackPrayerForDate(now);
      final tm = _fallbackPrayerForDate(tomorrow);
      return PrayerSchedule(
        today: t,
        tomorrowFajr: tm.firstWhere((p) => p.phase == PrayerPhase.fajr),
        todaySunrise: DateTime(now.year, now.month, now.day, 6, 20),
      );
    }
    final todayData = _computePrayerForDate(coords, settings, now);
    final tomorrowData = _computePrayerForDate(coords, settings, tomorrow);
    return PrayerSchedule(
      today: todayData.prayers,
      tomorrowFajr: tomorrowData.prayers.firstWhere(
        (p) => p.phase == PrayerPhase.fajr,
      ),
      todaySunrise: todayData.sunrise,
    );
  }
}
