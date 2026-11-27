import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers.dart';
import '../../../../core/security/app_security.dart';
import '../../../../core/ui_feedback.dart';
import '../../../../domain/entities/app_settings.dart';
import 'settings_ui_components.dart';

/// Shows a frosted Apple/Telegram-style dialog to set, change, or remove
/// the 4-digit app lock PIN. Expands from [anchorKey] and collapses back into it.
Future<bool?> showAppLockSheet(
  BuildContext context, {
  GlobalKey? anchorKey,
}) {
  final screenSize = MediaQuery.sizeOf(context);
  var scaleAlignment = Alignment.center;
  final renderBox = anchorKey?.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox != null && renderBox.hasSize) {
    final center = renderBox.localToGlobal(Offset.zero) +
        renderBox.size.center(Offset.zero);
    final ax = (center.dx / screenSize.width * 2 - 1).clamp(-1.0, 1.0);
    final ay = (center.dy / screenSize.height * 2 - 1).clamp(-1.0, 1.0);
    scaleAlignment = Alignment(ax, ay);
  }

  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) => const Directionality(
      textDirection: TextDirection.rtl,
      child: _AppLockDialog(),
    ),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final scaleAnim = Tween<double>(begin: 0.25, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        ),
      );

      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
              child: FadeTransition(
                opacity: curved,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: scaleAnim,
              alignment: scaleAlignment,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

class _AppLockDialog extends ConsumerStatefulWidget {
  const _AppLockDialog();

  @override
  ConsumerState<_AppLockDialog> createState() => _AppLockDialogState();
}

class _AppLockDialogState extends ConsumerState<_AppLockDialog>
    with SingleTickerProviderStateMixin {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  late final AnimationController _shakeController;
  bool _saving = false;
  bool _obscure = true;
  String? _errorText;

  static const _timeoutOptions = [
    SegmentOption<int>(value: 0, label: 'فوري'),
    SegmentOption<int>(value: 15, label: '15 ث'),
    SegmentOption<int>(value: 60, label: '1 د'),
    SegmentOption<int>(value: 300, label: '5 د'),
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  void _showInlineError(String message) {
    HapticFeedback.heavyImpact();
    setState(() => _errorText = message);
    _shakeController.forward(from: 0);
  }

  Future<void> _savePin(bool hasPin) async {
    setState(() => _errorText = null);
    if (hasPin) {
      final curr = _currentPinController.text.trim();
      if (!AppSecurity.verifyPin(curr)) {
        _showInlineError('الرمز الحالي غير صحيح.');
        return;
      }
    }

    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.isEmpty) {
      _showInlineError('يرجى إدخال الرمز الجديد أو الضغط على إلغاء القفل.');
      return;
    }
    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      _showInlineError('يجب أن يتكون الرمز من 4 أرقام.');
      return;
    }
    if (newPin != confirmPin) {
      _showInlineError('الرمزان غير متطابقين.');
      return;
    }

    setState(() => _saving = true);
    await AppSecurity.setPin(newPin);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pop(context, true);
    appSnack(context, 'تم حفظ رمز المرور بنجاح.');
  }

  Future<void> _removePin() async {
    setState(() => _errorText = null);
    final curr = _currentPinController.text.trim();
    if (!AppSecurity.verifyPin(curr)) {
      _showInlineError('الرمز الحالي غير صحيح.');
      return;
    }
    setState(() => _saving = true);
    await AppSecurity.removePin();
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    Navigator.pop(context, true);
    appSnack(context, 'تم إلغاء قفل التطبيق بنجاح.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasPin = AppSecurity.hasPinSet();
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final cardColor = isDark
        ? const Color(0xFF142035).withValues(alpha: 0.96)
        : const Color(0xFFF6F7F9).withValues(alpha: 0.98);

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: isDark ? 0.12 : 0.08,
                    ),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.5 : 0.18),
                      blurRadius: 32,
                      spreadRadius: -6,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(theme, isDark, hasPin),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: _errorText != null
                            ? Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFFF3B30),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorText!,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFFFF3B30),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final t = _shakeController.value;
                          final dx = t == 0
                              ? 0.0
                              : (1 - t) *
                                  10 *
                                  ((t * 16).floor().isEven ? 1 : -1);
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: SettingsGroupCard(
                          margin: EdgeInsets.zero,
                          dividerIndent: 16,
                          children: [
                            if (hasPin)
                              _PasscodeRow(
                                label: 'الرمز الحالي',
                                controller: _currentPinController,
                                focusNode: _currentFocus,
                                nextFocus: _newFocus,
                                obscure: _obscure,
                              ),
                            _PasscodeRow(
                              label:
                                  hasPin ? 'الرمز الجديد' : 'رمز المرور الجديد',
                              controller: _newPinController,
                              focusNode: _newFocus,
                              nextFocus: _confirmFocus,
                              obscure: _obscure,
                            ),
                            _PasscodeRow(
                              label: 'تأكيد الرمز',
                              controller: _confirmPinController,
                              focusNode: _confirmFocus,
                              obscure: _obscure,
                              onCompleted: () => _savePin(hasPin),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SettingsGroupCard(
                        margin: EdgeInsets.zero,
                        dividerIndent: 58,
                        children: [
                          SettingsSwitchTile(
                            icon: Icons.fingerprint_rounded,
                            iconColor: const Color(0xFF34C759),
                            title: 'فتح القفل بالبصمة / الوجه',
                            subtitle: 'تحقق سريع عند فتح التطبيق',
                            value: settings.biometricLockEnabled,
                            onChanged: (value) async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(
                                    settings.copyWith(
                                      biometricLockEnabled: value,
                                    ),
                                  );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 4,
                                    bottom: 10,
                                  ),
                                  child: Text(
                                    'مهلة القفل التلقائي بعد الخروج',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                AnimatedSegmentedControl<int>(
                                  options: _timeoutOptions,
                                  selected: settings.autoLockTimeoutSeconds,
                                  onChanged: (sec) async {
                                    await ref
                                        .read(settingsProvider.notifier)
                                        .updateSettings(
                                          settings.copyWith(
                                            autoLockTimeoutSeconds: sec,
                                          ),
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SoftActionButton(
                        icon: hasPin
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        label: hasPin ? 'تحديث الرمز' : 'تفعيل القفل',
                        color: theme.colorScheme.primary,
                        filledTint: true,
                        enabled: !_saving,
                        onTap: () => _savePin(hasPin),
                      ),
                      if (hasPin) ...[
                        const SizedBox(height: 8),
                        _SoftActionButton(
                          icon: Icons.lock_open_rounded,
                          label: 'إلغاء القفل نهائياً',
                          color: const Color(0xFFFF3B30),
                          filledTint: false,
                          enabled: !_saving,
                          onTap: _removePin,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, bool hasPin) {
    return Row(
      children: [
        SettingsIconBadge(
          icon: hasPin ? Icons.lock_rounded : Icons.shield_rounded,
          color: const Color(0xFF5856D6),
          size: 40,
          iconSize: 21,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPin ? 'إدارة قفل التطبيق' : 'تعيين رمز مرور',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16.5,
                ),
              ),
              Text(
                'رمز من 4 أرقام لحماية خصوصيتك',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: _obscure ? 'إظهار الأرقام' : 'إخفاء الأرقام',
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _obscure = !_obscure);
          },
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.onSurface.withValues(
              alpha: isDark ? 0.1 : 0.06,
            ),
            minimumSize: const Size(32, 32),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(
            Icons.close_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

class _PasscodeRow extends StatefulWidget {
  const _PasscodeRow({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.obscure,
    this.nextFocus,
    this.onCompleted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final bool obscure;
  final VoidCallback? onCompleted;

  @override
  State<_PasscodeRow> createState() => _PasscodeRowState();
}

class _PasscodeRowState extends State<_PasscodeRow> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onStateChanged);
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onStateChanged);
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = widget.controller.text;
    final focused = widget.focusNode.hasFocus;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.focusNode.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 1,
              height: 1,
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  enableInteractiveSelection: false,
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (val) {
                    if (val.length == 4) {
                      HapticFeedback.selectionClick();
                      if (widget.nextFocus != null) {
                        widget.nextFocus!.requestFocus();
                      } else {
                        widget.focusNode.unfocus();
                        widget.onCompleted?.call();
                      }
                    }
                  },
                ),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  final filled = index < text.length;
                  final active = focused && index == text.length.clamp(0, 3);
                  final boxBg = isDark
                      ? Colors.white.withValues(alpha: filled ? 0.12 : 0.05)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: filled ? 0.85 : 0.55);
                  final borderColor = active
                      ? theme.colorScheme.primary
                      : filled
                          ? theme.colorScheme.primary.withValues(alpha: 0.45)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.12);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 34,
                    height: 38,
                    decoration: BoxDecoration(
                      color: boxBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: active ? 1.5 : 0.8,
                      ),
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: filled ? 1.0 : 0.4,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutBack,
                        child: filled
                            ? (widget.obscure
                                ? Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : Text(
                                    text[index],
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ))
                            : const SizedBox.shrink(),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftActionButton extends StatelessWidget {
  const _SoftActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filledTint,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool filledTint;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = filledTint
        ? color.withValues(alpha: isDark ? 0.22 : 0.14)
        : color.withValues(alpha: isDark ? 0.14 : 0.10);

    return PressableScale(
      enabled: enabled,
      onTap: onTap,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          splashColor: color.withValues(alpha: 0.14),
          highlightColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 19),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
