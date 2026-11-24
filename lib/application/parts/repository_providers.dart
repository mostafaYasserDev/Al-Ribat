part of '../providers.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final box = Hive.box<String>('activities_box');
  return ActivityRepositoryImpl(box);
});

final workSessionRepositoryProvider = Provider<WorkSessionRepository>((ref) {
  final box = Hive.box<String>('work_sessions_box');
  return WorkSessionRepositoryImpl(box);
});

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepositoryImpl();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = Hive.box<String>('meta_box');
  return SettingsRepositoryImpl(box);
});

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  final box = Hive.box<String>('reflections_box');
  return ReflectionRepositoryImpl(box);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
