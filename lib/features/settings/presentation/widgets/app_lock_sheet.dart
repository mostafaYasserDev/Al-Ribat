import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/security/app_security.dart';
import '../../../../core/ui_feedback.dart';

/// Shows an Apple/Telegram-style modal bottom sheet to set, change, or remove
/// the 4-digit app lock PIN. Returns `true` if PIN state changed.
Future<bool?> showAppLockSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const Directionality(
      textDirection: TextDirection.rtl,
      child: _AppLockSheet(),
    ),
  );
}

class _AppLockSheet extends StatefulWidget {
  const _AppLockSheet();

  @override
  State<_AppLockSheet> createState() => _AppLockSheetState();
}

class _AppLockSheetState extends State<_AppLockSheet> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _savePin(bool hasPin) async {
    if (hasPin) {
      final curr = _currentPinController.text.trim();
      if (!AppSecurity.verifyPin(curr)) {
        appSnack(context, 'الرمز الحالي غير صحيح.');
        return;
      }
    }

    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.isEmpty) {
      appSnack(context, 'يرجى إدخال الرمز الجديد أو الضغط على إلغاء القفل.');
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

    setState(() => _saving = true);
    await AppSecurity.setPin(newPin);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    appSnack(context, 'تم حفظ رمز المرور بنجاح.');
    Navigator.pop(context, true);
  }

  Future<void> _removePin() async {
    final curr = _currentPinController.text.trim();
    if (!AppSecurity.verifyPin(curr)) {
      appSnack(context, 'الرمز الحالي غير صحيح.');
      return;
    }
    setState(() => _saving = true);
    await AppSecurity.removePin();
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    appSnack(context, 'تم إلغاء قفل التطبيق بنجاح.');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasPin = AppSecurity.hasPinSet();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ??
            (isDark ? const Color(0xFF111B2E) : Colors.white),
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasPin ? Icons.lock_rounded : Icons.lock_open_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasPin ? 'إدارة قفل التطبيق' : 'تعيين رمز مرور للتطبيق',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'رمز من 4 أرقام لحماية خصوصيتك',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (hasPin) ...[
              _PinField(
                controller: _currentPinController,
                hint: 'الرمز الحالي',
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 14),
            ],
            _PinField(
              controller: _newPinController,
              hint: hasPin ? 'الرمز الجديد (4 أرقام)' : 'أدخل 4 أرقام',
            ),
            const SizedBox(height: 10),
            _PinField(
              controller: _confirmPinController,
              hint: 'تأكيد الرمز الجديد',
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : () => _savePin(hasPin),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(hasPin ? 'تحديث الرمز' : 'تفعيل القفل'),
            ),
            if (hasPin) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : _removePin,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: const Text('إلغاء القفل نهائياً'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 4,
      obscureText: true,
      textAlign: TextAlign.center,
      style: const TextStyle(
        letterSpacing: 8,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          letterSpacing: 0,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        counterText: '',
      ),
    );
  }
}
