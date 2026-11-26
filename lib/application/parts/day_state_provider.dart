part of '../providers.dart';

/// Active tab index in [AppShell] (0: اليوم, 1: المشاريع, 2: التركيز, 3: التأملات, 4: الإعدادات).
final shellTabProvider = StateProvider<int>((ref) => 0);

final dayStateProvider = Provider<DayState>((ref) {
  final sched = ref.watch(prayerScheduleProvider).valueOrNull;
  final prayers = sched?.today ?? const <PrayerTime>[];
  final streak = ref.watch(streakProvider).valueOrNull ?? 0;
  final selectedDate = ref.watch(selectedDateProvider);
  final now = DateTime.now();

  PrayerPhase current = PrayerPhase.fajr;

  // If the selected date is in the past, default to Isha. If in the future, default to Fajr.
  if (selectedDate.year < now.year ||
      (selectedDate.year == now.year && selectedDate.month < now.month) ||
      (selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day < now.day)) {
    current = PrayerPhase.isha;
  } else if (selectedDate.year > now.year ||
      (selectedDate.year == now.year && selectedDate.month > now.month) ||
      (selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day > now.day)) {
    current = PrayerPhase.fajr;
  } else if (prayers.isNotEmpty && now.isBefore(prayers.first.time)) {
    current = PrayerPhase.isha;
  } else {
    for (final p in prayers) {
      if (now.isAfter(p.time)) {
        current = p.phase;
      }
    }
  }

  return DayState(currentPrayerPhase: current, streakCount: streak);
});
