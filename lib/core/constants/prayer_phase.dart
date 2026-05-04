import 'package:flutter/material.dart';

enum PrayerPhase { fajr, dhuhr, asr, maghrib, isha }

extension PrayerPhaseX on PrayerPhase {
  String get arabicName {
    switch (this) {
      case PrayerPhase.fajr:
        return 'الفجر';
      case PrayerPhase.dhuhr:
        return 'الظهر';
      case PrayerPhase.asr:
        return 'العصر';
      case PrayerPhase.maghrib:
        return 'المغرب';
      case PrayerPhase.isha:
        return 'العشاء';
    }
  }

  String get englishName {
    switch (this) {
      case PrayerPhase.fajr:
        return 'Fajr';
      case PrayerPhase.dhuhr:
        return 'Dhuhr';
      case PrayerPhase.asr:
        return 'Asr';
      case PrayerPhase.maghrib:
        return 'Maghrib';
      case PrayerPhase.isha:
        return 'Isha';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case PrayerPhase.fajr:
        return const [Color(0xFF152238), Color(0xFF2A3F66)];
      case PrayerPhase.dhuhr:
        return const [Color(0xFF545C66), Color(0xFF8E99A7)];
      case PrayerPhase.asr:
        return const [Color(0xFF78532D), Color(0xFFB1844A)];
      case PrayerPhase.maghrib:
        return const [Color(0xFF7A3D1A), Color(0xFFC46C3A)];
      case PrayerPhase.isha:
        return const [Color(0xFF0B1A33), Color(0xFF1A2A4A)];
    }
  }

  /// خلفيات أفتح للوضع الفاتح (اليوم) بدل التدرجات الداكنة الافتراضية.
  List<Color> get lightGradient {
    switch (this) {
      case PrayerPhase.fajr:
        return const [Color(0xFFD9E8F5), Color(0xFFE8F0FA)];
      case PrayerPhase.dhuhr:
        return const [Color(0xFFE5E8EC), Color(0xFFF2F4F7)];
      case PrayerPhase.asr:
        return const [Color(0xFFF2E6D8), Color(0xFFFAF0E6)];
      case PrayerPhase.maghrib:
        return const [Color(0xFFF5E4DC), Color(0xFFFAEFE8)];
      case PrayerPhase.isha:
        return const [Color(0xFFDDE5F3), Color(0xFFEEF2FA)];
    }
  }
}
