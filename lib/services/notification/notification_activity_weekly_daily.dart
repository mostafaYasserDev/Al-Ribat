part of '../notification_service.dart';

Future<int> _scheduleWeeklyActivity(
  NotificationService service,
  ActivityItem act,
  int nid,
  String bodyText,
  NotificationDetails activityDetails,
) async {
  for (final wd in act.repeatDays) {
    if (nid >= 9899) break;
    final when = _nextDartWeekdayOccurrence(
      act.reminderHour!,
      act.reminderMinute!,
      wd,
    );
    try {
      await _zonedScheduleWithFallback(
        service: service,
        id: nid,
        title: 'موعد نشاطك: ${act.title}',
        body: bodyText,
        when: when,
        details: activityDetails,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e, st) {
      reportError('NotificationService', e, st);
    }
    nid++;
  }
  return nid;
}

Future<int> _scheduleDailyActivity(
  NotificationService service,
  ActivityItem act,
  int nid,
  String bodyText,
  NotificationDetails activityDetails,
  String todayStr,
) async {
  final now = tz.TZDateTime.now(tz.local);
  var when = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    act.reminderHour!,
    act.reminderMinute!,
  );
  if (!when.isAfter(now) ||
      act.isDoneOn(todayStr) ||
      act.isSkippedOn(todayStr)) {
    when = when.add(const Duration(days: 1));
  }
  try {
    await _zonedScheduleWithFallback(
      service: service,
      id: nid,
      title: 'موعد نشاطك: ${act.title}',
      body: bodyText,
      when: when,
      details: activityDetails,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  } catch (e, st) {
    reportError('NotificationService', e, st);
  }
  return nid + 1;
}
