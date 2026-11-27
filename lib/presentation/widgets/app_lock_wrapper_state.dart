part of 'app_lock_wrapper.dart';

abstract class _AppLockWrapperAuthBase extends ConsumerState<AppLockWrapper>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isLocked = false;
  String _pinInput = '';
  String? _errorText;
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  late final AnimationController _shakeController;
  final FocusNode _keyboardFocusNode = FocusNode();
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
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    WidgetsBinding.instance.addObserver(this);
    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _shakeController.dispose();
    _keyboardFocusNode.dispose();
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
            _pinInput = '';
            _errorText = null;
          });
          if (_canCheckBiometrics && settings.biometricLockEnabled) {
            _authenticateBiometric();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(anim),
            child: child,
          ),
        );
      },
      child: _isLocked
          ? KeyedSubtree(
              key: const ValueKey('locked_screen'),
              child: _buildLockedScreen(context),
            )
          : KeyedSubtree(
              key: const ValueKey('unlocked_app'),
              child: widget.child,
            ),
    );
  }
}
