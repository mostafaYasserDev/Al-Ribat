part of '../providers.dart';

Future<void> _syncNotificationsAfterSchedule(
  Ref ref,
  PrayerSchedule schedule,
  AppSettings settings,
) async {
  final notifier = ref.read(notificationServiceProvider);
  try {
    await notifier.schedulePrayerNotifications(
      schedule.today,
      settings,
      tomorrowFajr: schedule.tomorrowFajr,
    );
  } catch (e, st) {
    reportError('schedulePrayerNotifications', e, st);
  }
  try {
    final activities = await ref.read(activityRepositoryProvider).loadAll();
    await notifier.scheduleActivityNotifications(activities, settings);
  } catch (e, st) {
    reportError('scheduleActivityNotifications', e, st);
  }
}

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final prayerScheduleProvider = FutureProvider<PrayerSchedule>((ref) async {
  final date = ref.watch(selectedDateProvider);
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (isToday) {
    return ref.watch(todayPrayerScheduleProvider.future);
  }
  // Keep today's notifications synced when settings change even while browsing another date.
  ref.watch(todayPrayerScheduleProvider);
  final settings = await ref.watch(settingsProvider.future);
  final repo = ref.watch(prayerRepositoryProvider);
  return repo.getPrayerSchedule(settings, date: date);
});

/// Real-time prayer schedule for [DateTime.now()], independent of [selectedDateProvider].
final todayPrayerScheduleProvider = FutureProvider<PrayerSchedule>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  final repo = ref.watch(prayerRepositoryProvider);
  final schedule = await repo.getPrayerSchedule(settings, date: DateTime.now());
  unawaited(_syncNotificationsAfterSchedule(ref, schedule, settings));
  return schedule;
});
