part of '../focus_foreground_service.dart';

/// مفاتيح تخزين جلسة التركيز.
abstract final class FocusForegroundPrefs {
  static const endMs = 'focus_fg_end_ms';
  static const title = 'focus_fg_title';
  static const plannedMin = 'focus_fg_planned_min';
  static const startedMs = 'focus_fg_started_ms';
  static const pausedRemainSec = 'focus_fg_paused_remain_sec';

  /// يُخزَّن عبر [SharedPreferences.setBool].
  static const paused = 'focus_fg_is_paused';
}

const int _focusServiceId = 887766;

const List<NotificationButton> _kFocusNotificationButtons = [
  NotificationButton(id: 'focus_pause', text: 'إيقاف مؤقت'),
  NotificationButton(id: 'focus_cancel', text: 'إلغاء'),
  NotificationButton(id: 'focus_save', text: 'حفظ'),
];

const List<NotificationButton> _kFocusPausedNotificationButtons = [
  NotificationButton(id: 'focus_resume', text: 'استئناف'),
  NotificationButton(id: 'focus_cancel', text: 'إلغاء'),
  NotificationButton(id: 'focus_save', text: 'حفظ'),
];

bool _pluginInited = false;

Future<void> ensureForegroundTaskPluginInitialized() async {
  if (_pluginInited) return;
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'focus_session_v2',
      channelName: 'جلسات التركيز — الرباط',
      channelDescription:
          'عرض الوقت المتبقي وأزرار الإيقاف المؤقت والاستئناف والإلغاء والحفظ الجزئي.',
      channelImportance: NotificationChannelImportance.DEFAULT,
      priority: NotificationPriority.DEFAULT,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: false,
    ),
  );
  _pluginInited = true;
}

@pragma('vm:entry-point')
void focusCountdownTaskCallback() {
  FlutterForegroundTask.setTaskHandler(FocusCountdownTaskHandler());
}
