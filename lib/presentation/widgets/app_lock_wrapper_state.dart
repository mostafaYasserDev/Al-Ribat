part of 'app_lock_wrapper.dart';

abstract class _AppLockWrapperAuthBase extends State<AppLockWrapper>
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
      // Re-lock if more than 15 seconds in background and PIN is set
      if (_lastPausedTime != null &&
          DateTime.now().difference(_lastPausedTime!).inSeconds >= 15) {
        if (AppSecurity.hasPinSet() && !_isLocked) {
          setState(() {
            _isLocked = true;
            _pinController.clear();
          });
          if (_canCheckBiometrics) {
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
