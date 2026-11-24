part of '../prayer_repository_impl.dart';

Future<void> _fetchAndCacheCurrentPosition(Box<String>? box) async {
  try {
    final position = await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 6),
    );
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
