part of '../notification_service.dart';

Future<void> _schedulePrayerNotifications(
  NotificationService service,
  List<PrayerTime> prayers,
  AppSettings settings, {
  PrayerTime? tomorrowFajr,
  List<PrayerTime>? additionalPrayers,
}) async {
  if (!NotificationService._notificationsSupported) return;
  await service._ready;
  if (!settings.notificationsEnabled) {
    await service._plugin.cancelAll();
    return;
  }
  await _ensureNotificationPermission(service);

  await _cancelPendingWhere(
    service,
    (id) => (id >= 1 && id <= 40) || (id >= 100 && id < 200),
  );

  final combinedPrayers = <PrayerTime>[
    ...prayers,
    if (tomorrowFajr != null) tomorrowFajr,
    ...?additionalPrayers,
  ];

  // Deduplicate by identical phase and day
  final seen = <String>{};
  final uniquePrayers = <PrayerTime>[];
  for (final p in combinedPrayers) {
    final key = '${p.phase.name}_${p.time.year}_${p.time.month}_${p.time.day}';
    if (seen.add(key)) {
      uniquePrayers.add(p);
    }
  }

  for (var i = 0; i < uniquePrayers.length; i++) {
    final p = uniquePrayers[i];
    final scheduled = p.time.subtract(
      Duration(minutes: settings.focusLeadMinutes),
    );
    final afterPrayerPrompt = p.time.add(
      Duration(minutes: settings.prayerSlotDurationMinutes),
    );
    if (scheduled.isBefore(DateTime.now()) &&
        afterPrayerPrompt.isBefore(DateTime.now())) {
      continue;
    }

    if (settings.focusModeEnabled) {
      await _schedulePrayerLead(service, p, i, settings, scheduled);
    }
    if (settings.phasePromptsEnabled) {
      await _schedulePhasePrompt(service, p, i, afterPrayerPrompt);
    }
  }
}
