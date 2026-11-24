part of '../settings_screen.dart';

extension _SettingsLockDialogActions on _SettingsScreenState {
  List<Widget> _buildLockDialogActions(
    BuildContext ctx,
    BuildContext context,
    bool hasPin,
    TextEditingController currentPinController,
    TextEditingController newPinController,
    TextEditingController confirmPinController,
  ) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('إلغاء'),
      ),
      if (hasPin) _removePinAction(ctx, context, currentPinController),
      _savePinAction(
        ctx,
        context,
        hasPin,
        currentPinController,
        newPinController,
        confirmPinController,
      ),
    ];
  }

  Widget _removePinAction(
    BuildContext ctx,
    BuildContext context,
    TextEditingController currentPinController,
  ) {
    return TextButton(
      onPressed: () async {
        final curr = currentPinController.text.trim();
        if (!AppSecurity.verifyPin(curr)) {
          appSnack(context, 'الرمز الحالي غير صحيح.');
          return;
        }
        await AppSecurity.removePin();
        if (context.mounted) {
          appSnack(context, 'تم إلغاء قفل التطبيق بنجاح.');
          Navigator.pop(ctx);
        }
      },
      child: const Text('إلغاء القفل نهائياً',
          style: TextStyle(color: Colors.red)),
    );
  }

  Widget _savePinAction(
    BuildContext ctx,
    BuildContext context,
    bool hasPin,
    TextEditingController currentPinController,
    TextEditingController newPinController,
    TextEditingController confirmPinController,
  ) {
    return FilledButton(
      onPressed: () async {
        if (hasPin) {
          final curr = currentPinController.text.trim();
          if (!AppSecurity.verifyPin(curr)) {
            appSnack(context, 'الرمز الحالي غير صحيح.');
            return;
          }
        }

        final newPin = newPinController.text.trim();
        final confirmPin = confirmPinController.text.trim();

        if (newPin.isEmpty) {
          appSnack(
              context, 'يرجى إدخال الرمز الجديد أو الضغط على إلغاء القفل.');
          return;
        }

        if (newPin.length != 4 || int.tryParse(newPin) == null) {
          appSnack(context, 'يجب أن يتكون الرمز من 4 أرقام.');
          return;
        }

        if (newPin != confirmPin) {
          appSnack(context, 'الرمزان غير متطابقين.');
          return;
        }

        await AppSecurity.setPin(newPin);
        if (context.mounted) {
          appSnack(context, 'تم حفظ رمز المرور بنجاح.');
          Navigator.pop(ctx);
        }
      },
      child: const Text('حفظ'),
    );
  }
}
