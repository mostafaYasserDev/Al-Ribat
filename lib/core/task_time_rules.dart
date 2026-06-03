import '../core/constants/prayer_phase.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/task_item.dart';

DateTime _phaseTime(PrayerSchedule schedule, PrayerPhase phase) {
  return schedule.today.firstWhere((p) => p.phase == phase).time;
}

DateTime _nextPrayerTime(PrayerSchedule schedule, PrayerPhase phase) {
  final idx = schedule.today.indexWhere((p) => p.phase == phase);
  if (idx >= 0 && idx < schedule.today.length - 1) {
    return schedule.today[idx + 1].time;
  }
  return schedule.tomorrowFajr.time;
}

DateTime _previousPrayerTime(PrayerSchedule schedule, PrayerPhase phase) {
  final idx = schedule.today.indexWhere((p) => p.phase == phase);
  if (idx > 0) {
    return schedule.today[idx - 1].time;
  }
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

({DateTime start, DateTime end}) taskAllowedRange({
  required PrayerSchedule schedule,
  required PrayerPhase phase,
  required TaskType type,
  required int prayerSlotMinutes,
}) {
  if (type == TaskType.after) {
    final start = _phaseTime(schedule, phase).add(Duration(minutes: prayerSlotMinutes));
    final end = _nextPrayerTime(schedule, phase);
    return (start: start, end: end);
  }
  final start = _previousPrayerTime(schedule, phase).add(Duration(minutes: prayerSlotMinutes));
  final end = _phaseTime(schedule, phase);
  return (start: start, end: end);
}

({PrayerPhase prayer, TaskType type}) inferPrayerTypeForMinute({
  required PrayerSchedule schedule,
  required int minuteOfDay,
}) {
  final n = DateTime.now();
  final point = DateTime(n.year, n.month, n.day).add(Duration(minutes: minuteOfDay));
  final today = schedule.today;
  if (today.isEmpty) {
    return (prayer: PrayerPhase.asr, type: TaskType.after);
  }
  DateTime prev = today.first.time;
  PrayerPhase prevPhase = today.first.phase;
  DateTime next = schedule.tomorrowFajr.time;
  PrayerPhase nextPhase = schedule.tomorrowFajr.phase;
  for (var i = 0; i < today.length; i++) {
    final cur = today[i];
    final nx = i < today.length - 1 ? today[i + 1] : schedule.tomorrowFajr;
    if (!point.isBefore(cur.time) && point.isBefore(nx.time)) {
      prev = cur.time;
      prevPhase = cur.phase;
      next = nx.time;
      nextPhase = nx.phase;
      break;
    }
    if (point.isBefore(today.first.time)) {
      return (prayer: PrayerPhase.fajr, type: TaskType.before);
    }
  }
  final dPrev = point.difference(prev).abs();
  final dNext = next.difference(point).abs();
  if (dNext < dPrev) {
    return (prayer: nextPhase, type: TaskType.before);
  }
  return (prayer: prevPhase, type: TaskType.after);
}

