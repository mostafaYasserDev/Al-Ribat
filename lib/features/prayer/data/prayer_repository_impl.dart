import 'dart:async';
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

import 'package:al_ribat/core/errors/error_reporter.dart';
import 'package:al_ribat/domain/entities/app_settings.dart';
import 'location_search_service.dart';
import '../domain/prayer_phase.dart';
import '../domain/prayer_repository.dart';
import '../domain/prayer_schedule.dart';
import '../domain/prayer_time.dart';

class _PrayerDayData {
  const _PrayerDayData({required this.prayers, required this.sunrise});

  final List<PrayerTime> prayers;
  final DateTime sunrise;
}

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
    if (coords == null) {
      return fallbackSchedule(now);
    }
    final tomorrow = now.add(const Duration(days: 1));
    final todayData = _computePrayerForDate(coords, settings, now);
    final tomorrowData = _computePrayerForDate(coords, settings, tomorrow);
    return PrayerSchedule(
      today: todayData.prayers,
      tomorrowFajr:
          tomorrowData.prayers.firstWhere((p) => p.phase == PrayerPhase.fajr),
      todaySunrise: todayData.sunrise,
    );
  }

  static PrayerSchedule fallbackSchedule(DateTime now) {
    final tomorrow = now.add(const Duration(days: 1));
    final t = fallbackPrayerForDate(now);
    final tm = fallbackPrayerForDate(tomorrow);
    return PrayerSchedule(
      today: t,
      tomorrowFajr: tm.firstWhere((p) => p.phase == PrayerPhase.fajr),
      todaySunrise: DateTime(now.year, now.month, now.day, 6, 20),
    );
  }

  Future<Coordinates?> _resolvePrayerCoordinates(AppSettings settings) async {
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
    final box =
        Hive.isBoxOpen('meta_box') ? Hive.box<String>('meta_box') : null;
    final cached = _getCachedPrayerCoordinates(box);
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return isMobile ? cached : await _desktopIpFallback(box, cached);
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return isMobile ? cached : await _desktopIpFallback(box, cached);
      }

      // If we have lastKnown position, use it immediately and refresh in background
      if (isMobile) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _saveCachedPrayerCoordinates(
            box,
            lastKnown.latitude,
            lastKnown.longitude,
          );
          unawaited(_fetchAndCacheCurrentPosition(box));
          return Coordinates(lastKnown.latitude, lastKnown.longitude);
        }
      }

      // If we have cached coordinates from previous session, return immediately
      if (cached != null) {
        unawaited(_fetchAndCacheCurrentPosition(box));
        return cached;
      }

      // First run with no cache: medium accuracy locks reliably indoors
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 12));
      _saveCachedPrayerCoordinates(box, position.latitude, position.longitude);
      return Coordinates(position.latitude, position.longitude);
    } catch (e, st) {
      reportError('PrayerRepository', e, st);
      return isMobile ? cached : await _desktopIpFallback(box, cached);
    }
  }

  Future<Coordinates?> _desktopIpFallback(
    Box<String>? box,
    Coordinates? cached,
  ) async {
    if (cached != null) return cached;
    final ipLoc = await LocationSearchService.detectApproximateLocationByIp();
    if (ipLoc != null) {
      _saveCachedPrayerCoordinates(box, ipLoc.latitude, ipLoc.longitude);
      return Coordinates(ipLoc.latitude, ipLoc.longitude);
    }
    return null;
  }

  Future<void> _fetchAndCacheCurrentPosition(Box<String>? box) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 12));
      _saveCachedPrayerCoordinates(box, position.latitude, position.longitude);
    } catch (e, st) {
      reportError('PrayerRepository', e, st);
    }
  }

  Coordinates? _getCachedPrayerCoordinates(Box<String>? box) {
    if (box == null) return null;
    final latStr = box.get('cached_gps_lat');
    final lngStr = box.get('cached_gps_lng');
    if (latStr != null && lngStr != null) {
      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);
      if (lat != null && lng != null) {
        return Coordinates(lat, lng);
      }
    }
    return null;
  }

  void _saveCachedPrayerCoordinates(Box<String>? box, double lat, double lng) {
    if (box == null) return;
    box.put('cached_gps_lat', lat.toString());
    box.put('cached_gps_lng', lng.toString());
  }

  static ({double latitude, double longitude})? cachedGpsCoordinates() {
    if (!Hive.isBoxOpen('meta_box')) return null;
    final box = Hive.box<String>('meta_box');
    final latStr = box.get('cached_gps_lat');
    final lngStr = box.get('cached_gps_lng');
    if (latStr == null || lngStr == null) return null;
    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);
    if (lat == null || lng == null) return null;
    return (latitude: lat, longitude: lng);
  }

  _PrayerDayData _computePrayerForDate(
    Coordinates coordinates,
    AppSettings settings,
    DateTime date,
  ) {
    final params = _toPrayerMethod(settings.prayerMethod).getParameters()
      ..madhab =
          settings.asrMadhab == AsrMadhab.hanafi ? Madhab.hanafi : Madhab.shafi;
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

  CalculationMethod _toPrayerMethod(PrayerCalculationMethod method) {
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

  static List<PrayerTime> fallbackPrayerForDate(DateTime date) {
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
