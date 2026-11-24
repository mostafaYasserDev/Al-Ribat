part of '../prayer_repository_impl.dart';

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
  final box = Hive.isBoxOpen('meta_box') ? Hive.box<String>('meta_box') : null;
  final cached = _getCachedPrayerCoordinates(box);

  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return cached;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return cached;
    }

    // If we have lastKnown position, use it immediately and refresh in background
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

    // If we have cached coordinates from previous session, return immediately
    if (cached != null) {
      unawaited(_fetchAndCacheCurrentPosition(box));
      return cached;
    }

    // First run with no cache: wait with a short timeout to prevent UI freezing
    final position = await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 4),
    );
    _saveCachedPrayerCoordinates(box, position.latitude, position.longitude);
    return Coordinates(position.latitude, position.longitude);
  } catch (e, st) {
    reportError('PrayerRepository', e, st);
    return cached;
  }
}
