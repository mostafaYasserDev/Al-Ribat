part of '../notification_service.dart';

Future<void> _schedulePrayerLead(
  NotificationService service,
  PrayerTime p,
  int i,
  AppSettings settings,
  DateTime scheduled,
) async {
  if (!scheduled.isAfter(DateTime.now())) return;
  try {
    await _zonedScheduleWithFallback(
      service: service,
      id: i + 1,
      title: 'اقترب وقت ${p.phase.arabicName}',
      body: settings.focusModeEnabled
          ? 'وضع الهدوء مفعل. أنهِ ما لديك واستعد للصلاة.'
          : 'استعد بهدوء للصلاة القادمة',
      when: tz.TZDateTime.from(scheduled, tz.local),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService._prayerChannelId,
          'تنبيهات اقتراب الصلاة',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  } catch (e, st) {
    reportError('NotificationService', e, st);
  }
}

Future<void> _schedulePhasePrompt(
  NotificationService service,
  PrayerTime p,
  int i,
  DateTime afterPrayerPrompt,
) async {
  if (!afterPrayerPrompt.isAfter(DateTime.now())) return;
  try {
    await _zonedScheduleWithFallback(
      service: service,
      id: 100 + i,
      title: 'بدأت مرحلة ${p.phase.arabicName}',
      body: 'ما المهمة أو النشاط الذي تريد إنجازه الآن؟',
      when: tz.TZDateTime.from(afterPrayerPrompt, tz.local),
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationService._phaseChannelId,
          'مراحل اليوم وأوقات الصلاة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
    );
  } catch (e, st) {
    reportError('NotificationService', e, st);
  }
}
