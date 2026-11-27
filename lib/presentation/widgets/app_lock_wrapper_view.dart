part of 'app_lock_wrapper.dart';

extension _AppLockWrapperView on _AppLockWrapperState {
  Widget _buildLockedScreen(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final showBio = _canCheckBiometrics && settings.biometricLockEnabled;

    final bgColors = isDark
        ? const [Color(0xFF0A1220), Color(0xFF101C32), Color(0xFF0A1424)]
        : const [Color(0xFFF3F6F9), Color(0xFFE9F1EE), Color(0xFFF6F8FA)];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.backspace) {
            _backspace();
            return;
          }
          final char = event.character;
          if (char != null && char.length == 1 && int.tryParse(char) != null) {
            _appendDigit(char);
          }
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.22),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تطبيق الرباط',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'أدخل رمز المرور للمتابعة',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _buildPasscodeDots(theme, isDark),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 32,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: _errorText != null
                                ? Container(
                                    key: ValueKey(_errorText),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _errorText!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: const Color(0xFFFF3B30),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildKeypad(theme, isDark, showBio),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasscodeDots(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final dx =
            t == 0 ? 0.0 : (1 - t) * 14 * ((t * 18).floor().isEven ? 1 : -1);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final filled = index < _pinInput.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 11),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? theme.colorScheme.primary : Colors.transparent,
                border: Border.all(
                  color: filled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(
                          alpha: isDark ? 0.35 : 0.28,
                        ),
                  width: 1.6,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: AnimatedScale(
                scale: filled ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutBack,
                child: const SizedBox.expand(),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme, bool isDark, bool showBio) {
    final disabled = _cooldownSeconds > 0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          _keypadRow(['1', '2', '3'], theme, isDark, disabled),
          const SizedBox(height: 14),
          _keypadRow(['4', '5', '6'], theme, isDark, disabled),
          const SizedBox(height: 14),
          _keypadRow(['7', '8', '9'], theme, isDark, disabled),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: showBio
                    ? _IosKeypadAction(
                        icon: Icons.fingerprint_rounded,
                        color: theme.colorScheme.primary,
                        isDark: isDark,
                        onTap: _authenticateBiometric,
                      )
                    : const SizedBox.shrink(),
              ),
              _IosKeypadDigit(
                digit: '0',
                isDark: isDark,
                enabled: !disabled,
                onTap: () => _appendDigit('0'),
              ),
              SizedBox(
                width: 72,
                height: 72,
                child: AnimatedOpacity(
                  opacity: _pinInput.isNotEmpty && !disabled ? 1.0 : 0.28,
                  duration: const Duration(milliseconds: 160),
                  child: _IosKeypadAction(
                    icon: Icons.backspace_outlined,
                    color: theme.colorScheme.onSurface,
                    isDark: isDark,
                    onTap:
                        _pinInput.isNotEmpty && !disabled ? _backspace : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keypadRow(
    List<String> digits,
    ThemeData theme,
    bool isDark,
    bool disabled,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (d) => _IosKeypadDigit(
              digit: d,
              isDark: isDark,
              enabled: !disabled,
              onTap: () => _appendDigit(d),
            ),
          )
          .toList(),
    );
  }
}

class _IosKeypadDigit extends StatelessWidget {
  const _IosKeypadDigit({
    required this.digit,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  final String digit;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.white.withValues(alpha: 0.86);

    return PressableScale(
      enabled: enabled,
      onTap: onTap,
      child: Material(
        color: bg,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.14),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Text(
                digit,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 27,
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IosKeypadAction extends StatelessWidget {
  const _IosKeypadAction({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: onTap != null,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: color.withValues(alpha: 0.14),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
