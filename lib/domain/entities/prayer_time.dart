import '../../core/constants/prayer_phase.dart';

class PrayerTime {
  const PrayerTime({
    required this.phase,
    required this.time,
  });

  final PrayerPhase phase;
  final DateTime time;
}
