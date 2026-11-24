import 'dart:io';

import 'package:al_ribat/core/errors/error_reporter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/prayer_phase.dart';
import '../domain/entities/activity_item.dart';
import '../domain/entities/app_settings.dart';
import '../domain/entities/prayer_time.dart';
import 'motivation_quotes.dart';

part 'notification/notification_initialization.dart';
part 'notification/notification_permissions.dart';
part 'notification/notification_scheduling.dart';
part 'notification/notification_prayers.dart';
part 'notification/notification_prayer_details.dart';
part 'notification/notification_activities.dart';
part 'notification/notification_activity_weekly_daily.dart';
part 'notification/notification_activity_once_monthly.dart';
part 'notification/notification_focus.dart';

class NotificationService {
  static const _activityChannelId = 'activity_reminders_v2';
  static const _prayerChannelId = 'prayer_reminders_v2';
  static const _phaseChannelId = 'phase_prompts_v2';
  static const _focusChannelId = 'focus_complete_v2';
  static const _focusCompleteNotificationId = 971002;

  NotificationService() {
    _ready = _initializeNotifications(this);
  }

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  late final Future<void> _ready;

  /// التنبيهات مدعومة على المنصّات المحمولة فقط؛ معاينة سطح المكتب تتجاهلها
  /// بهدوء حتى تبقى الشاشات قابلة للعرض والتجربة.
  static bool get _notificationsSupported =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  Future<void> ensureNotificationPermission() =>
      _ensureNotificationPermission(this);

  Future<void> schedulePrayerNotifications(
    List<PrayerTime> prayers,
    AppSettings settings, {
    PrayerTime? tomorrowFajr,
    List<PrayerTime>? additionalPrayers,
  }) =>
      _schedulePrayerNotifications(
        this,
        prayers,
        settings,
        tomorrowFajr: tomorrowFajr,
        additionalPrayers: additionalPrayers,
      );

  Future<void> scheduleActivityNotifications(
    List<ActivityItem> activities,
    AppSettings settings,
  ) =>
      _scheduleActivityNotifications(this, activities, settings);

  Future<void> showFocusSessionComplete({
    required String sessionTitle,
    required String body,
  }) =>
      _showFocusSessionComplete(
        this,
        sessionTitle: sessionTitle,
        body: body,
      );
}
