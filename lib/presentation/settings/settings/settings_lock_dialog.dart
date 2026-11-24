part of '../settings_screen.dart';

extension _SettingsLockDialog on _SettingsScreenState {
  void _showAppLockDialog(BuildContext context) {
    final hasPin = AppSecurity.hasPinSet();
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title:
                Text(hasPin ? 'إدارة قفل التطبيق' : 'تعيين رمز مرور للتطبيق'),
            content: _buildLockDialogContent(
              hasPin,
              currentPinController,
              newPinController,
              confirmPinController,
            ),
            actions: _buildLockDialogActions(
              ctx,
              context,
              hasPin,
              currentPinController,
              newPinController,
              confirmPinController,
            ),
          );
        },
      ),
    );
  }
}
