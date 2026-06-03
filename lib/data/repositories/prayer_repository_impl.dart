import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/prayer_phase.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/prayer_repository.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  @override
  Future<List<PrayerTime>> getPrayerTimesForToday(AppSettings settings, {DateTime? date}) async {
    final s = await getPrayerSchedule(settings, date: date);
    return s.today;
  }

  @override
  Future<PrayerSchedule> getPrayerSchedule(AppSettings settings, {DateTime? date}) async {
    final coords = await _resolveCoordinates(settings);
    final now = date ?? DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    if (coords == null) {
      final t = _fallbackForDate(now);
      final tm = _fallbackForDate(tomorrow);
      return PrayerSchedule(
        today: t,
        tomorrowFajr: tm.firstWhere((p) => p.phase == PrayerPhase.fajr),
        todaySunrise: DateTime(now.year, now.month, now.day, 6, 20),
      );
    }
    final todayData = _computeForDate(coords, settings, now);
    final tomorrowData = _computeForDate(coords, settings, tomorrow);
    return PrayerSchedule(
      today: todayData.prayers,
      tomorrowFajr: tomorrowData.prayers.firstWhere((p) => p.phase == PrayerPhase.fajr),
      todaySunrise: todayData.sunrise,
    );
  }

  Future<Coordinates?> _resolveCoordinates(AppSettings settings) async {
    if (settings.prayerLocationMode == PrayerLocationMode.manual) {
      final lat = settings.manualLatitude;
      final lng = settings.manualLongitude;
      if (lat != null && lng != null) {
        return Coordinates(lat, lng);
      }
      return null;
    }
    return _coordinatesFromGps();
  }

  Future<Coordinates?> _coordinatesFromGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        try {
          final position = await Geolocator.getCurrentPosition().timeout(
            const Duration(seconds: 3),
          );
          return Coordinates(position.latitude, position.longitude);
        } catch (_) {
          return Coordinates(lastKnown.latitude, lastKnown.longitude);
        }
      }

      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 20),
      );
      return Coordinates(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  _PrayerDayData _computeForDate(
    Coordinates coordinates,
    AppSettings settings,
    DateTime date,
  ) {
    final params = _toMethod(settings.prayerMethod).getParameters()..madhab = Madhab.shafi;
    final dc = DateComponents(date.year, date.month, date.day);
    final prayerTimes = PrayerTimes(coordinates, dc, params);
    return _PrayerDayData(
      sunrise: prayerTimes.sunrise,
      prayers: [
      PrayerTime(phase: PrayerPhase.fajr, time: prayerTimes.fajr),
      PrayerTime(phase: PrayerPhase.dhuhr, time: prayerTimes.dhuhr),
      PrayerTime(phase: PrayerPhase.asr, time: prayerTimes.asr),
      PrayerTime(phase: PrayerPhase.maghrib, time: prayerTimes.maghrib),
      PrayerTime(phase: PrayerPhase.isha, time: prayerTimes.isha),
      ],
    );
  }

  CalculationMethod _toMethod(PrayerCalculationMethod method) {
    switch (method) {
      case PrayerCalculationMethod.muslimWorldLeague:
        return CalculationMethod.muslim_world_league;
      case PrayerCalculationMethod.egyptian:
        return CalculationMethod.egyptian;
      case PrayerCalculationMethod.karachi:
        return CalculationMethod.karachi;
      case PrayerCalculationMethod.ummAlQura:
        return CalculationMethod.umm_al_qura;
      case PrayerCalculationMethod.dubai:
        return CalculationMethod.dubai;
    }
  }

  List<PrayerTime> _fallbackForDate(DateTime date) {
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
}

class _PrayerDayData {
  const _PrayerDayData({required this.prayers, required this.sunrise});

  final List<PrayerTime> prayers;
  final DateTime sunrise;
}
