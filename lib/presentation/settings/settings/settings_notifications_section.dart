part of '../settings_screen.dart';

extension _SettingsNotificationCards on _SettingsScreenState {
  Widget _buildNotificationsCard(BuildContext context, AppSettings settings) {
    return Card(
      child: SwitchListTile(
        value: settings.notificationsEnabled,
        title: const Text('تفعيل الإشعارات'),
        onChanged: (value) async {
          HapticFeedback.selectionClick();
          if (value) {
            await AppPermissions.requestNotificationIfNeeded();
            await AppPermissions.requestExactAlarmIfNeeded();
            await AppPermissions.requestIgnoreBatteryOptimizationsIfNeeded();
          }
          await ref.read(settingsProvider.notifier).updateSettings(
                settings.copyWith(notificationsEnabled: value),
              );
        },
      ),
    );
  }

  Widget _buildAlarmPermissionCard(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('إذن التنبيه في الوقت المحدد (أندرويد)'),
        subtitle: const Text(
          'إذا ظهرت رسالة رفض التنبيهات الدقيقة، افتح إعدادات التطبيق واسمح بالتنبيهات في الوقت المحدد.',
        ),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => openAppSettings(),
      ),
    );
  }

  Widget _buildFocusModeCard(BuildContext context, AppSettings settings) {
    return Card(
      child: SwitchListTile(
        value: settings.focusModeEnabled,
        title: const Text('وضع الهدوء قبل الصلاة'),
        subtitle: const Text('تنبيه للاستعداد الذهني قبل وقت الصلاة'),
        onChanged: (value) async {
          await ref.read(settingsProvider.notifier).updateSettings(
                settings.copyWith(focusModeEnabled: value),
              );
        },
      ),
    );
  }
}
