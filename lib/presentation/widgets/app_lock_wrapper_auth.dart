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
        HapticFeedback.mediumImpact();
        setState(() {
          _isLocked = false;
          _pinInput = '';
          _errorText = null;
          _failedAttempts = 0;
        });
      }
    } catch (e) {
      reportError('AppLock biometric auth', e);
    } finally {
      _lastPausedTime = null;
      _isAuthenticating = false;
    }
  }

  void _appendDigit(String digit) {
    if (_cooldownSeconds > 0 || _pinInput.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _errorText = null;
      _pinInput += digit;
    });
    if (_pinInput.length == 4) {
      Future.delayed(const Duration(milliseconds: 90), () {
        if (mounted && _pinInput.length == 4) {
          _verifyPin();
        }
      });
    }
  }

  void _backspace() {
    if (_cooldownSeconds > 0 || _pinInput.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _pinInput = _pinInput.substring(0, _pinInput.length - 1);
    });
  }

  void _verifyPin() {
    if (_cooldownSeconds > 0) return;
    if (AppSecurity.verifyPin(_pinInput)) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isLocked = false;
        _pinInput = '';
        _errorText = null;
        _failedAttempts = 0;
      });
      _lastPausedTime = null;
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _startCooldown(30);
      } else {
        setState(() {
          _pinInput = '';
          _errorText = 'رمز المرور غير صحيح';
        });
      }
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() {
      _pinInput = '';
      _cooldownSeconds = seconds;
      _errorText = 'محاولات كثيرة، انتظر $_cooldownSeconds ثانية';
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          timer.cancel();
          _failedAttempts = 0;
          _errorText = null;
        } else {
          _errorText = 'محاولات كثيرة، انتظر $_cooldownSeconds ثانية';
        }
      });
    });
  }
}
