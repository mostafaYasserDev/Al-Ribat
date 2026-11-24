part of '../notification_service.dart';

Future<int> _scheduleOnceActivity(
  NotificationService service,
  ActivityItem act,
  int nid,
  String bodyText,
  NotificationDetails activityDetails,
  String todayStr,
) async {
  if (act.isDoneOn(todayStr) || act.isSkippedOn(todayStr)) {
    return nid;
  }
  final target = act.targetDate;
  if (target == null || target != todayStr) return nid;
  final now = tz.TZDateTime.now(tz.local);
  final when = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    act.reminderHour!,
    act.reminderMinute!,
  );
  if (when.isAfter(now)) {
    try {
      await _zonedScheduleWithFallback(
        service: service,
        id: nid,
        title: 'موعد نشاطك: ${act.title}',
        body: bodyText,
        when: when,
        details: activityDetails,
      );
    } catch (e, st) {
      reportError('NotificationService', e, st);
    }
    nid++;
  }
  return nid;
}

Future<int> _scheduleMonthlyActivity(
  NotificationService service,
  ActivityItem act,
  int nid,
  String bodyText,
  NotificationDetails activityDetails,
) async {
  final tzNow = tz.TZDateTime.now(tz.local);
  if (!act.repeatDays.contains(tzNow.day)) return nid;
  var when = tz.TZDateTime(
    tz.local,
    tzNow.year,
    tzNow.month,
    tzNow.day,
    act.reminderHour!,
    act.reminderMinute!,
  );
  if (when.isAfter(tzNow)) {
    try {
      await _zonedScheduleWithFallback(
        service: service,
        id: nid,
        title: 'موعد نشاطك: ${act.title}',
        body: bodyText,
        when: when,
        details: activityDetails,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e, st) {
      reportError('NotificationService', e, st);
    }
    nid++;
  }
  return nid;
}
