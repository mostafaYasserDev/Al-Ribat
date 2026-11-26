part of 'app_lock_wrapper.dart';

mixin _AppLockWrapperAuth on _AppLockWrapperAuthBase {
  void _checkLock() async {
    final hasPin = AppSecurity.hasPinSet();
    try {
      _canCheckBiometrics =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (_) {
      _canCheckBiometrics = false;
    }

    if (hasPin) {
      final settings =
          ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
      setState(() {
        _isLocked = true;
      });
      if (_canCheckBiometrics && settings.biometricLockEnabled) {
        _authenticateBiometric();
      }
    }
  }

  Future<void> _authenticateBiometric() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'قم بالتحقق لفتح تطبيق الرباط',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated && mounted) {
        setState(() {
          _isLocked = false;
        });
      }
    } catch (e) {
      reportError('AppLock biometric auth', e);
    } finally {
      _lastPausedTime = null;
      _isAuthenticating = false;
    }
  }

  void _verifyPin() {
    final entered = _pinController.text.trim();
    if (AppSecurity.verifyPin(entered)) {
      setState(() {
        _isLocked = false;
      });
      _pinController.clear();
      _lastPausedTime = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرمز غير صحيح')),
      );
      _pinController.clear();
    }
  }
}
