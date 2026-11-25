import 'package:flutter_test/flutter_test.dart';

import 'package:al_ribat/features/prayer/data/location_search_service.dart';

void main() {
  group('LocationSearchService Tests', () {
    test('searchLocal matches Arabic and English city aliases', () {
      final cairoAr = LocationSearchService.searchLocal('القاهرة');
      expect(cairoAr, isNotEmpty);
      expect(cairoAr.first.name, 'القاهرة');

      final asyutEn = LocationSearchService.searchLocal('asyut');
      expect(asyutEn, isNotEmpty);
      expect(asyutEn.first.name, 'أسيوط');
      expect(asyutEn.first.fullLabel, 'أسيوط، مصر');
    });

    test('parseNominatimJson parses valid OpenStreetMap results', () {
      const sampleJson = '''
      [
        {
          "lat": "27.1809",
          "lon": "31.1837",
          "name": "أسيوط",
          "display_name": "أسيوط، مصر",
          "address": {
            "city": "أسيوط",
            "state": "محافظة أسيوط",
            "country": "مصر"
          }
        }
      ]
      ''';

      final results = LocationSearchService.parseNominatimJson(sampleJson);
      expect(results.length, 1);
      expect(results.first.name, 'أسيوط');
      expect(results.first.subtitle, 'محافظة أسيوط، مصر');
      expect(results.first.latitude, closeTo(27.1809, 0.0001));
      expect(results.first.longitude, closeTo(31.1837, 0.0001));
    });

    test('parseIpWhoIsJson parses city coordinates and handles failures', () {
      const validIpJson = '''
      {
        "success": true,
        "city": "Cairo",
        "country": "Egypt",
        "latitude": 30.0444,
        "longitude": 31.2357
      }
      ''';
      final result = LocationSearchService.parseIpWhoIsJson(validIpJson);
      expect(result, isNotNull);
      expect(result!.name, 'Cairo');
      expect(result.subtitle, 'Egypt');
      expect(result.latitude, closeTo(30.0444, 0.0001));

      const failedIpJson = '{"success": false}';
      expect(LocationSearchService.parseIpWhoIsJson(failedIpJson), isNull);
    });
  });
}
