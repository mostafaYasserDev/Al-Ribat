part of 'app_lock_wrapper.dart';

abstract class _AppLockWrapperAuthBase extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  final TextEditingController _pinController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  DateTime? _lastPausedTime;
  bool _isAuthenticating = false;
}

class _AppLockWrapperState extends _AppLockWrapperAuthBase
    with _AppLockWrapperAuth {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (!_isAuthenticating) {
        _lastPausedTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isAuthenticating) return;
      final settings =
          ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
      final timeoutSec = settings.autoLockTimeoutSeconds;
      if (_lastPausedTime != null &&
          DateTime.now().difference(_lastPausedTime!).inSeconds >= timeoutSec) {
        if (AppSecurity.hasPinSet() && !_isLocked) {
          setState(() {
            _isLocked = true;
            _pinController.clear();
          });
          if (_canCheckBiometrics && settings.biometricLockEnabled) {
            _authenticateBiometric();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      _isLocked ? _buildLockedScreen(context) : widget.child;
}
