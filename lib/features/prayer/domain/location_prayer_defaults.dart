import 'package:al_ribat/features/settings/domain/app_settings.dart';

/// Infers smart regional defaults for prayer calculation method and Asr madhab
/// based on location name or geographic coordinates.
abstract final class LocationPrayerDefaults {
  static ({PrayerCalculationMethod method, AsrMadhab madhab}) infer({
    String? locationLabel,
    double? latitude,
    double? longitude,
  }) {
    final label = (locationLabel ?? '').toLowerCase().trim();
    if (label.isNotEmpty) {
      if (_matchesAny(label, _egyptKeywords)) {
        return (
          method: PrayerCalculationMethod.egyptian,
          madhab: AsrMadhab.shafi,
        );
      }
      if (_matchesAny(label, _uaeKeywords)) {
        return (
          method: PrayerCalculationMethod.dubai,
          madhab: AsrMadhab.shafi,
        );
      }
      if (_matchesAny(label, _saudiKeywords)) {
        return (
          method: PrayerCalculationMethod.ummAlQura,
          madhab: AsrMadhab.shafi,
        );
      }
      if (_matchesAny(label, _southAsiaKeywords)) {
        return (
          method: PrayerCalculationMethod.karachi,
          madhab: AsrMadhab.hanafi,
        );
      }
      if (_matchesAny(label, _hanafiMwlKeywords)) {
        return (
          method: PrayerCalculationMethod.muslimWorldLeague,
          madhab: AsrMadhab.hanafi,
        );
      }
    }

    if (latitude != null && longitude != null) {
      // Egypt
      if (latitude >= 22.0 &&
          latitude <= 31.7 &&
          longitude >= 24.7 &&
          longitude <= 36.9) {
        return (
          method: PrayerCalculationMethod.egyptian,
          madhab: AsrMadhab.shafi,
        );
      }
      // UAE (checked before broader Saudi Arabia box)
      if (latitude >= 22.6 &&
          latitude <= 26.1 &&
          longitude >= 51.5 &&
          longitude <= 56.4) {
        return (
          method: PrayerCalculationMethod.dubai,
          madhab: AsrMadhab.shafi,
        );
      }
      // Saudi Arabia
      if (latitude >= 16.3 &&
          latitude <= 32.2 &&
          longitude >= 34.5 &&
          longitude <= 55.7) {
        return (
          method: PrayerCalculationMethod.ummAlQura,
          madhab: AsrMadhab.shafi,
        );
      }
      // Pakistan, India, Bangladesh
      if (latitude >= 6.0 &&
          latitude <= 37.1 &&
          longitude >= 60.8 &&
          longitude <= 97.4) {
        return (
          method: PrayerCalculationMethod.karachi,
          madhab: AsrMadhab.hanafi,
        );
      }
      // Turkey
      if (latitude >= 35.8 &&
          latitude <= 42.1 &&
          longitude >= 26.0 &&
          longitude <= 44.8) {
        return (
          method: PrayerCalculationMethod.muslimWorldLeague,
          madhab: AsrMadhab.hanafi,
        );
      }
    }

    return (
      method: PrayerCalculationMethod.muslimWorldLeague,
      madhab: AsrMadhab.shafi,
    );
  }

  static bool _matchesAny(String value, List<String> keywords) {
    for (final k in keywords) {
      if (value.contains(k)) return true;
    }
    return false;
  }

  static const _egyptKeywords = [
    'مصر',
    'egypt',
    'القاهرة',
    'قاهرة',
    'cairo',
    'الإسكندرية',
    'اسكندرية',
    'alexandria',
    'أسيوط',
    'اسيوط',
    'asyut',
    'assiut',
    'المنصورة',
    'منصورة',
    'mansoura',
    'الجيزة',
    'giza',
    'أسوان',
    'الأقصر',
    'طنطا',
    'الزقازيق',
  ];

  static const _saudiKeywords = [
    'السعودية',
    'saudi',
    'مكة',
    'makkah',
    'mecca',
    'المدينة',
    'madinah',
    'medina',
    'الرياض',
    'رياض',
    'riyadh',
    'جدة',
    'jeddah',
    'jiddah',
    'الدمام',
    'dammam',
    'الخبر',
  ];

  static const _uaeKeywords = [
    'الإمارات',
    'الامارات',
    'emirates',
    'uae',
    'دبي',
    'dubai',
    'أبو ظبي',
    'ابو ظبي',
    'ابوظبي',
    'abu dhabi',
    'الشارقة',
    'sharjah',
  ];

  static const _southAsiaKeywords = [
    'باكستان',
    'pakistan',
    'karachi',
    'lahore',
    'islamabad',
    'الهند',
    'india',
    'delhi',
    'mumbai',
    'بنغلاديش',
    'bangladesh',
    'dhaka',
  ];

  static const _hanafiMwlKeywords = [
    'تركيا',
    'turkey',
    'türkiye',
    'إسطنبول',
    'اسطنبول',
    'istanbul',
    'ankara',
    'أفغانستان',
    'afghanistan',
    'kabul',
  ];
}

