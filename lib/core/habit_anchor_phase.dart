import '../domain/entities/habit_item.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/prayer_time.dart';
import 'constants/prayer_phase.dart';

/// هل تُفعَّل العادة في يوم [day] حسب أيام التكرار؟
bool habitIsActiveOnWeekday(HabitItem habit, int dartWeekday) {
  return habit.effectiveWeekdays.contains(dartWeekday);
}

/// المرحلة التي تُعرض تحتها العادة: الفترة «بعد هذه الصلاة» حتى الصلاة التالية
/// (ومن العشاء إلى فجر الغد).
PrayerPhase anchorPrayerPhaseForReminder(PrayerSchedule schedule, HabitItem habit) {
  final n = DateTime.now();
  final reminder = DateTime(n.year, n.month, n.day, habit.reminderHour, habit.reminderMinute);
  return anchorPrayerPhaseForPointInDay(schedule, reminder);
}

PrayerTime _byPhase(List<PrayerTime> prayers, PrayerPhase ph) =>
    prayers.firstWhere((p) => p.phase == ph);

/// نفس منطق [anchorPrayerPhaseForReminder] لأي لحظة في يوم جدول اليوم.
PrayerPhase anchorPrayerPhaseForPointInDay(PrayerSchedule schedule, DateTime point) {
  final prayers = schedule.today;
  final f = _byPhase(prayers, PrayerPhase.fajr).time;
  final d = _byPhase(prayers, PrayerPhase.dhuhr).time;
  final a = _byPhase(prayers, PrayerPhase.asr).time;
  final m = _byPhase(prayers, PrayerPhase.maghrib).time;
  final i = _byPhase(prayers, PrayerPhase.isha).time;
  final fNext = schedule.tomorrowFajr.time;

  if (point.isBefore(f)) return PrayerPhase.fajr;
  if (point.isBefore(d)) return PrayerPhase.fajr;
  if (point.isBefore(a)) return PrayerPhase.dhuhr;
  if (point.isBefore(m)) return PrayerPhase.asr;
  if (point.isBefore(i)) return PrayerPhase.maghrib;
  if (point.isBefore(fNext)) return PrayerPhase.isha;
  return PrayerPhase.fajr;
}
