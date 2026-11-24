part of '../add_activity_sheet.dart';

mixin _Notifications on _SheetStateCore {
  List<Widget> _buildNotifications(BuildContext context) {
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('تفعيل التذكير'),
        value: _notificationsEnabled,
        onChanged: (v) async {
          setState(() => _notificationsEnabled = v);
          if (v) {
            await ref
                .read(notificationServiceProvider)
                .ensureNotificationPermission();
          }
        },
      ),
      if (_notificationsEnabled)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('وقت التذكير'),
          trailing: Text(_reminderTime.format(context)),
          onTap: () async {
            final p = await showTimePicker(
              context: context,
              initialTime: _reminderTime,
            );
            if (p != null) setState(() => _reminderTime = p);
          },
        ),
    ];
  }
}
