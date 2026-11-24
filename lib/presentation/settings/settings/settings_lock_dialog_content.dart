part of '../settings_screen.dart';

extension _SettingsLockDialogContent on _SettingsScreenState {
  Widget _buildLockDialogContent(
    bool hasPin,
    TextEditingController currentPinController,
    TextEditingController newPinController,
    TextEditingController confirmPinController,
  ) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasPin) ...[
            const Text('أدخل الرمز الحالي أولاً:'),
            const SizedBox(height: 8),
            TextField(
              controller: currentPinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'الرمز الحالي',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
          ],
          Text(
            hasPin
                ? 'الرمز الجديد (اتركه فارغاً لإلغاء القفل):'
                : 'أدخل 4 أرقام لرمز المرور الجديد:',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: newPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '4 أرقام',
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmPinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'تأكيد الرمز الجديد',
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}
