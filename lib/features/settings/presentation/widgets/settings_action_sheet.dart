import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnchoredMenuOption<T> {
  const AnchoredMenuOption({
    required this.value,
    required this.title,
    required this.icon,
    this.subtitle,
    this.color,
    this.isDestructive = false,
  });

  final T value;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final bool isDestructive;
}

/// Shows an Apple iOS / Telegram-style floating menu that expands directly from
/// the [anchorKey] widget and collapses smoothly back into it on dismiss.
Future<T?> showAnchoredSettingsMenu<T>({
  required BuildContext context,
  required GlobalKey anchorKey,
  required String title,
  String? subtitle,
  required List<AnchoredMenuOption<T>> options,
}) {
  final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  final screenSize = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);

  Rect anchorRect;
  if (renderBox != null && renderBox.hasSize) {
    final topLeft = renderBox.localToGlobal(Offset.zero);
    anchorRect = topLeft & renderBox.size;
  } else {
    anchorRect = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: 48,
      height: 48,
    );
  }

  const horizontalMargin = 16.0;
  final menuWidth =
      (screenSize.width - horizontalMargin * 2).clamp(240.0, 340.0);

  // Place below anchor if there is enough space, otherwise above.
  final spaceBelow = screenSize.height - padding.bottom - anchorRect.bottom;
  final showBelow =
      spaceBelow >= 230 || spaceBelow >= anchorRect.top - padding.top;

  final double left = (anchorRect.center.dx - menuWidth / 2).clamp(
    horizontalMargin,
    screenSize.width - menuWidth - horizontalMargin,
  );
  final double? top = showBelow ? (anchorRect.bottom + 8) : null;
  final double? bottom =
      showBelow ? null : (screenSize.height - anchorRect.top + 8);

  // Compute scale origin alignment relative to the menu card so it springs
  // directly out of (and back into) the tapped button.
  final relX =
      ((anchorRect.center.dx - left) / menuWidth * 2 - 1).clamp(-1.0, 1.0);
  final scaleAlignment = Alignment(relX, showBelow ? -1.0 : 1.0);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) {
      return _AnchoredMenuOverlay<T>(
        left: left,
        top: top,
        bottom: bottom,
        width: menuWidth,
        title: title,
        subtitle: subtitle,
        options: options,
      );
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final scaleAnim = Tween<double>(begin: 0.42, end: 1.0).animate(
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
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.24),
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

class _AnchoredMenuOverlay<T> extends StatelessWidget {
  const _AnchoredMenuOverlay({
    required this.left,
    required this.top,
    required this.bottom,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final double left;
  final double? top;
  final double? bottom;
  final double width;
  final String title;
  final String? subtitle;
  final List<AnchoredMenuOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF162238).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);
    final dividerColor =
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.08);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            bottom: bottom,
            width: width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: isDark ? 0.12 : 0.07,
                    ),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                      blurRadius: 28,
                      spreadRadius: -4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.58),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Divider(height: 0.6, thickness: 0.6, color: dividerColor),
                    for (var i = 0; i < options.length; i++) ...[
                      _AnchoredMenuRow<T>(option: options[i]),
                      if (i < options.length - 1)
                        Divider(
                          height: 0.6,
                          thickness: 0.6,
                          indent: 52,
                          color: dividerColor,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnchoredMenuRow<T> extends StatelessWidget {
  const _AnchoredMenuRow({required this.option});

  final AnchoredMenuOption<T> option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = option.isDestructive
        ? const Color(0xFFFF3B30)
        : (option.color ?? theme.colorScheme.primary);

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).pop(option.value);
      },
      splashColor: accent.withValues(alpha: 0.08),
      highlightColor: accent.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(option.icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: option.isDestructive ? accent : null,
                    ),
                  ),
                  if (option.subtitle != null &&
                      option.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      option.subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.56),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
