import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Captures the global [Rect] of [context]'s render box.
Rect? _captureAnchorRect(BuildContext? context) {
  if (context == null || !context.mounted) return null;
  final ro = context.findRenderObject();
  if (ro is! RenderBox || !ro.hasSize) return null;
  return ro.localToGlobal(Offset.zero) & ro.size;
}

/// Shows an Apple / Telegram-inspired popover anchored to [anchorContext].
/// Morphs the anchor button into a soft-red close (`✕`) button while open,
/// expanding the popover directly from the anchor and collapsing back on close.
Future<T?> showAnchoredPopover<T>(
  BuildContext anchorContext, {
  required Widget Function(BuildContext popoverContext) builder,
  double width = 256,
  bool preferAbove = true,
  double anchorRadius = 12,
}) {
  final anchorRect = _captureAnchorRect(anchorContext);
  if (anchorRect == null) {
    return showDialog<T>(
      context: anchorContext,
      builder: (ctx) => Center(child: builder(ctx)),
    );
  }

  return Navigator.of(anchorContext).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 190),
      pageBuilder: (ctx, animation, _) => _AnchoredPopoverOverlay(
        anchorRect: anchorRect,
        width: width,
        preferAbove: preferAbove,
        anchorRadius: anchorRadius,
        animation: animation,
        child: builder(ctx),
      ),
    ),
  );
}

class _AnchoredPopoverOverlay extends StatelessWidget {
  const _AnchoredPopoverOverlay({
    required this.anchorRect,
    required this.width,
    required this.preferAbove,
    required this.anchorRadius,
    required this.animation,
    required this.child,
  });

  final Rect anchorRect;
  final double width;
  final bool preferAbove;
  final double anchorRadius;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final cardWidth = width.clamp(180.0, screen.width - 24.0);

    final spaceAbove = anchorRect.top - media.padding.top - 10;
    final spaceBelow =
        screen.height - media.padding.bottom - anchorRect.bottom - 10;
    final showAbove = (preferAbove && spaceAbove >= 190) ||
        (!preferAbove && spaceBelow < 160 && spaceAbove > spaceBelow);

    final double left;
    if (anchorRect.center.dx < screen.width / 2) {
      left = anchorRect.left.clamp(12.0, screen.width - cardWidth - 12.0);
    } else {
      left = (anchorRect.right - cardWidth)
          .clamp(12.0, screen.width - cardWidth - 12.0);
    }

    final ax =
        (((anchorRect.center.dx - left) / cardWidth) * 2 - 1).clamp(-1.0, 1.0);
    final ay = showAbove ? 1.0 : -1.0;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    const closeRed = Color(0xFFFF3B30);

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          final t = curved.value;
          return Stack(
            children: [
              // Subtle scrim
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.22 * t),
                  ),
                ),
              ),

              // Popover card blooming from anchor
              Positioned(
                left: left,
                width: cardWidth,
                top: showAbove ? null : anchorRect.bottom + 8,
                bottom: showAbove ? (screen.height - anchorRect.top + 8) : null,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(
                    alignment: Alignment(ax, ay),
                    scale: 0.25 + (0.75 * t),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: isDark ? 0.1 : 0.07),
                          width: 0.7,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: (isDark ? 0.42 : 0.16) * t,
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),

              // Morphing trigger button (... -> soft red X) at exact anchor position
              Positioned(
                left: anchorRect.left,
                top: anchorRect.top,
                width: anchorRect.width,
                height: anchorRect.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        Color.alphaBlend(
                          closeRed.withValues(alpha: isDark ? 0.24 : 0.14),
                          cardBg,
                        ),
                        t,
                      ),
                      borderRadius: BorderRadius.circular(anchorRadius),
                      border: Border.all(
                        color: closeRed.withValues(alpha: 0.35 * t),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: (1 - t) * -0.6,
                        child: Icon(
                          t > 0.35
                              ? Icons.close_rounded
                              : Icons.more_horiz_rounded,
                          size: 19,
                          color: Color.lerp(
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                            closeRed,
                            t,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Clean Telegram/Apple-style action row inside an anchored popover.
class PopoverActionRow extends StatelessWidget {
  const PopoverActionRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? color : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
