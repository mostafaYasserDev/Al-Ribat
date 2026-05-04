import '../../core/constants/prayer_phase.dart';

class DayState {
  const DayState({
    required this.currentPrayerPhase,
    required this.streakCount,
  });

  final PrayerPhase currentPrayerPhase;
  final int streakCount;
}
