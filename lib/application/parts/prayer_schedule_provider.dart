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
  final settings = await ref.watch(settingsProvider.future);
  final repo = ref.watch(prayerRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final schedule = await repo.getPrayerSchedule(settings, date: date);
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (isToday) {
    unawaited(_syncNotificationsAfterSchedule(ref, schedule, settings));
  }
  return schedule;
});
