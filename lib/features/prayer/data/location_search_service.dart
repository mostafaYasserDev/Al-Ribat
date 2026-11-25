import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class LocationSearchResult {
  const LocationSearchResult({
    required this.name,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String subtitle;
  final double latitude;
  final double longitude;

  String get fullLabel => subtitle.isEmpty ? name : '$name، $subtitle';
}

class CityPreset {
  const CityPreset({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.aliases = const [],
  });

  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final List<String> aliases;
}

/// Cross-platform location search & IP geolocation fallback service.
/// Works identically on Linux, Windows, macOS, Android, and iOS.
abstract final class LocationSearchService {
  static const List<CityPreset> popularCities = [
    CityPreset(
      name: 'مكة المكرمة',
      country: 'السعودية',
      latitude: 21.4225,
      longitude: 39.8262,
      aliases: ['مكة', 'makkah', 'mecca'],
    ),
    CityPreset(
      name: 'المدينة المنورة',
      country: 'السعودية',
      latitude: 24.4672,
      longitude: 39.6111,
      aliases: ['المدينة', 'madinah', 'medina'],
    ),
    CityPreset(
      name: 'القدس الشريف',
      country: 'فلسطين',
      latitude: 31.7683,
      longitude: 35.2137,
      aliases: ['القدس', 'jerusalem', 'quds'],
    ),
    CityPreset(
      name: 'القاهرة',
      country: 'مصر',
      latitude: 30.0444,
      longitude: 31.2357,
      aliases: ['cairo', 'قاهرة'],
    ),
    CityPreset(
      name: 'الإسكندرية',
      country: 'مصر',
      latitude: 31.2001,
      longitude: 29.9187,
      aliases: ['اسكندرية', 'alexandria'],
    ),
    CityPreset(
      name: 'أسيوط',
      country: 'مصر',
      latitude: 27.1809,
      longitude: 31.1837,
      aliases: ['اسيوط', 'asyut', 'assiut'],
    ),
    CityPreset(
      name: 'المنصورة',
      country: 'مصر',
      latitude: 31.0409,
      longitude: 31.3785,
      aliases: ['منصورة', 'mansoura'],
    ),
    CityPreset(
      name: 'الرياض',
      country: 'السعودية',
      latitude: 24.7136,
      longitude: 46.6753,
      aliases: ['رياض', 'riyadh'],
    ),
    CityPreset(
      name: 'جدة',
      country: 'السعودية',
      latitude: 21.5433,
      longitude: 39.1728,
      aliases: ['jeddah', 'jiddah'],
    ),
    CityPreset(
      name: 'الدمام',
      country: 'السعودية',
      latitude: 26.4207,
      longitude: 50.0888,
      aliases: ['دماام', 'dammam'],
    ),
    CityPreset(
      name: 'دبي',
      country: 'الإمارات',
      latitude: 25.2048,
      longitude: 55.2708,
      aliases: ['dubai'],
    ),
    CityPreset(
      name: 'أبو ظبي',
      country: 'الإمارات',
      latitude: 24.4539,
      longitude: 54.3773,
      aliases: ['ابو ظبي', 'ابوظبي', 'abu dhabi'],
    ),
    CityPreset(
      name: 'عمّان',
      country: 'الأردن',
      latitude: 31.9454,
      longitude: 35.9284,
      aliases: ['عمان', 'amman'],
    ),
    CityPreset(
      name: 'الكويت',
      country: 'الكويت',
      latitude: 29.3759,
      longitude: 47.9774,
      aliases: ['kuwait'],
    ),
    CityPreset(
      name: 'الدوحة',
      country: 'قطر',
      latitude: 25.2854,
      longitude: 51.5310,
      aliases: ['دوحة', 'doha'],
    ),
    CityPreset(
      name: 'المنامة',
      country: 'البحرين',
      latitude: 26.2285,
      longitude: 50.5860,
      aliases: ['منامة', 'manama'],
    ),
    CityPreset(
      name: 'مسقط',
      country: 'عُمان',
      latitude: 23.5880,
      longitude: 58.3829,
      aliases: ['muscat'],
    ),
    CityPreset(
      name: 'بغداد',
      country: 'العراق',
      latitude: 33.3152,
      longitude: 44.3661,
      aliases: ['baghdad'],
    ),
    CityPreset(
      name: 'دمشق',
      country: 'سوريا',
      latitude: 33.5138,
      longitude: 36.2765,
      aliases: ['damascus'],
    ),
    CityPreset(
      name: 'بيروت',
      country: 'لبنان',
      latitude: 33.8938,
      longitude: 35.5018,
      aliases: ['beirut'],
    ),
    CityPreset(
      name: 'طرابلس',
      country: 'ليبيا',
      latitude: 32.8872,
      longitude: 13.1913,
      aliases: ['tripoli'],
    ),
    CityPreset(
      name: 'تونس',
      country: 'تونس',
      latitude: 36.8065,
      longitude: 10.1815,
      aliases: ['tunis'],
    ),
    CityPreset(
      name: 'الجزائر',
      country: 'الجزائر',
      latitude: 36.7538,
      longitude: 3.0588,
      aliases: ['algiers'],
    ),
    CityPreset(
      name: 'الرباط',
      country: 'المغرب',
      latitude: 34.0209,
      longitude: -6.8416,
      aliases: ['رباط', 'rabat'],
    ),
    CityPreset(
      name: 'الدار البيضاء',
      country: 'المغرب',
      latitude: 33.5731,
      longitude: -7.5898,
      aliases: ['casablanca'],
    ),
    CityPreset(
      name: 'الخرطوم',
      country: 'السودان',
      latitude: 15.5007,
      longitude: 32.5599,
      aliases: ['khartoum'],
    ),
    CityPreset(
      name: 'إسطنبول',
      country: 'تركيا',
      latitude: 41.0082,
      longitude: 28.9784,
      aliases: ['اسطنبول', 'istanbul'],
    ),
    CityPreset(
      name: 'لندن',
      country: 'المملكة المتحدة',
      latitude: 51.5072,
      longitude: -0.1276,
      aliases: ['london'],
    ),
    CityPreset(
      name: 'باريس',
      country: 'فرنسا',
      latitude: 48.8566,
      longitude: 2.3522,
      aliases: ['paris'],
    ),
  ];

  /// Instant offline search across built-in Arab and international cities.
  static List<LocationSearchResult> searchLocal(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final matches = <LocationSearchResult>[];
    for (final city in popularCities) {
      final nameMatch = city.name.toLowerCase().contains(q);
      final countryMatch = city.country.toLowerCase().contains(q);
      final aliasMatch = city.aliases.any((a) => a.toLowerCase().contains(q));
      if (nameMatch || countryMatch || aliasMatch) {
        matches.add(
          LocationSearchResult(
            name: city.name,
            subtitle: city.country,
            latitude: city.latitude,
            longitude: city.longitude,
          ),
        );
      }
    }
    return matches;
  }

  /// Cross-platform search: queries OpenStreetMap Nominatim first (works on
  /// Linux, Android, iOS, macOS, Windows), merges offline local matches,
  /// and falls back to native `geocoding` on Android/iOS if offline/blocked.
  static Future<List<LocationSearchResult>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    final localMatches = searchLocal(q);
    final onlineResults = await _searchNominatim(q);

    if (onlineResults.isNotEmpty) {
      final seen = <String>{};
      final merged = <LocationSearchResult>[];
      for (final r in [...onlineResults, ...localMatches]) {
        final key =
            '${r.latitude.toStringAsFixed(2)},${r.longitude.toStringAsFixed(2)}';
        if (seen.add(key)) {
          merged.add(r);
        }
      }
      return merged.take(8).toList();
    }

    if (localMatches.isNotEmpty) {
      return localMatches;
    }

    // Native mobile fallback only (geocoding does not support Desktop/Linux)
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return _searchNativeMobileFallback(q);
    }

    return const [];
  }

  static Future<List<LocationSearchResult>> _searchNominatim(
      String query) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 7);
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'ar',
        'limit': '6',
      });
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'AlRibatApp/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 7));
      if (response.statusCode != 200) return const [];

      final body = await response.transform(utf8.decoder).join();
      return parseNominatimJson(body);
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  @visibleForTesting
  static List<LocationSearchResult> parseNominatimJson(String jsonBody) {
    final decoded = jsonDecode(jsonBody);
    if (decoded is! List) return const [];

    final results = <LocationSearchResult>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;

      final address = item['address'];
      String name = item['name']?.toString().trim() ?? '';
      String subtitle = '';

      if (address is Map) {
        final city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['municipality'] ??
            address['county'] ??
            address['state'];
        final country = address['country'];
        if (name.isEmpty && city != null) {
          name = city.toString().trim();
        }
        final parts = <String>[
          if (address['state'] != null &&
              address['state'].toString().trim() != name)
            address['state'].toString().trim(),
          if (country != null) country.toString().trim(),
        ];
        subtitle = parts.join('، ');
      }

      if (name.isEmpty) {
        final display = item['display_name']?.toString() ?? '';
        name = display.split(',').first.trim();
      }

      if (name.isNotEmpty) {
        results.add(
          LocationSearchResult(
            name: name,
            subtitle: subtitle,
            latitude: lat,
            longitude: lon,
          ),
        );
      }
    }
    return results;
  }

  static Future<List<LocationSearchResult>> _searchNativeMobileFallback(
      String query) async {
    try {
      final found = await locationFromAddress(query);
      final results = <LocationSearchResult>[];
      for (final loc in found.take(5)) {
        var name = query;
        var subtitle = '';
        try {
          final marks =
              await placemarkFromCoordinates(loc.latitude, loc.longitude);
          if (marks.isNotEmpty) {
            final p = marks.first;
            final locality = (p.locality ?? '').trim();
            final state = (p.administrativeArea ?? '').trim();
            final country = (p.country ?? '').trim();
            if (locality.isNotEmpty) name = locality;
            subtitle = [
              if (state.isNotEmpty && state != name) state,
              if (country.isNotEmpty) country,
            ].join('، ');
          }
        } catch (_) {}
        results.add(
          LocationSearchResult(
            name: name,
            subtitle: subtitle,
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  /// Approximate city-level location via IP geolocation (used on Desktop/Linux
  /// when system GPS / GeoClue is unavailable).
  static Future<LocationSearchResult?> detectApproximateLocationByIp() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.https('ipwho.is', '/', {'lang': 'ar'});
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'AlRibatApp/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      return parseIpWhoIsJson(body);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @visibleForTesting
  static LocationSearchResult? parseIpWhoIsJson(String jsonBody) {
    final decoded = jsonDecode(jsonBody);
    if (decoded is! Map) return null;
    if (decoded['success'] == false) return null;

    final lat = (decoded['latitude'] as num?)?.toDouble();
    final lon = (decoded['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final city = decoded['city']?.toString().trim() ?? '';
    final country = decoded['country']?.toString().trim() ?? '';
    return LocationSearchResult(
      name: city.isNotEmpty ? city : 'الموقع التقريبي',
      subtitle: country,
      latitude: lat,
      longitude: lon,
    );
  }
}
