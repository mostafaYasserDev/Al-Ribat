import '../domain/entities/prayer_schedule.dart';

/// True if [start]–[end] overlaps any prayer quiet window
/// [prayerTime, prayerTime + slotMinutes).
bool prayerSlotOverlaps({
  required PrayerSchedule schedule,
  required int slotMinutes,
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  if (!rangeEnd.isAfter(rangeStart)) {
    return false;
  }
  final ranges = _blockedWindows(schedule, slotMinutes);
  for (final w in ranges) {
    if (rangeStart.isBefore(w.$2) && w.$1.isBefore(rangeEnd)) {
      return true;
    }
  }
  return false;
}

List<(DateTime, DateTime)> _blockedWindows(PrayerSchedule schedule, int slotMinutes) {
  final slot = Duration(minutes: slotMinutes);
  final out = <(DateTime, DateTime)>[];
  for (final p in schedule.today) {
    out.add((p.time, p.time.add(slot)));
  }
  out.add((schedule.tomorrowFajr.time, schedule.tomorrowFajr.time.add(slot)));
  return out;
}

/// Reminder at [hour]:[minute] today — conflicts if inside any blocked window today.
bool habitReminderConflicts({
  required PrayerSchedule schedule,
  required int slotMinutes,
  required int hour,
  required int minute,
}) {
  final now = DateTime.now();
  final at = DateTime(now.year, now.month, now.day, hour, minute);
  final ranges = _blockedWindows(schedule, slotMinutes);
  for (final w in ranges) {
    if (!at.isBefore(w.$1) && at.isBefore(w.$2)) {
      return true;
    }
  }
  return false;
}

/// If [at] is inside a blocked prayer window, returns the first valid instant
/// right after the window; otherwise returns [at] unchanged.
DateTime nextAllowedMoment({
  required PrayerSchedule schedule,
  required int slotMinutes,
  required DateTime at,
}) {
  final ranges = _blockedWindows(schedule, slotMinutes);
  for (final w in ranges) {
    if (!at.isBefore(w.$1) && at.isBefore(w.$2)) {
      return w.$2;
    }
  }
  return at;
}
