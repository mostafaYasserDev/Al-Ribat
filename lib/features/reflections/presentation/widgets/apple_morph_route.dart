import 'package:flutter/material.dart';

/// Captures the global [Rect] of a widget from its [BuildContext].
Rect? captureWidgetRect(BuildContext? context) {
  if (context == null || !context.mounted) return null;
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  final offset = renderObject.localToGlobal(Offset.zero);
  return offset & renderObject.size;
}

/// Apple-inspired spatial container morph route.
/// Smoothly expands from [sourceRect] with [sourceColor] and [sourceRadius]
/// into full screen using an organic deceleration curve, and collapses back
/// into the exact origin on pop.
class AppleMorphRoute<T> extends PageRouteBuilder<T> {
  AppleMorphRoute({
    required WidgetBuilder builder,
    Rect? sourceRect,
    Color? sourceColor,
    double sourceRadius = 16,
  }) : super(
          opaque: false,
          barrierDismissible: false,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 270),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const appleCurve = Cubic(0.22, 1.0, 0.36, 1.0);
            final curved = CurvedAnimation(
              parent: animation,
              curve: appleCurve,
              reverseCurve: Curves.easeInCubic,
            );

            // Fallback smooth fade + subtle scale if sourceRect is unavailable
            if (sourceRect == null) {
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
                  child: child,
                ),
              );
            }

            final screenSize = MediaQuery.sizeOf(context);
            final targetRect = Rect.fromLTWH(
              0,
              0,
              screenSize.width,
              screenSize.height,
            );
            final rectAnim =
                RectTween(begin: sourceRect, end: targetRect).animate(curved);
            final radiusAnim =
                Tween<double>(begin: sourceRadius, end: 0.0).animate(curved);
            final contentFade = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.22, 0.85, curve: Curves.easeOut),
              reverseCurve: const Interval(0.0, 0.6, curve: Curves.easeIn),
            );
            final contentOffset =
                Tween<double>(begin: 14.0, end: 0.0).animate(contentFade);
            final resolvedBg =
                sourceColor ?? Theme.of(context).colorScheme.surface;

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final rect = rectAnim.value ?? targetRect;
                final radius = radiusAnim.value;
                return Stack(
                  children: [
                    // Subtle spatial depth scrim
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black.withValues(
                            alpha: 0.24 * curved.value,
                          ),
                        ),
                      ),
                    ),
                    // Expanding physical container
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: Material(
                        color: resolvedBg,
                        elevation: 0,
                        borderRadius: BorderRadius.circular(radius),
                        clipBehavior: Clip.antiAlias,
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minWidth: screenSize.width,
                          maxWidth: screenSize.width,
                          minHeight: screenSize.height,
                          maxHeight: screenSize.height,
                          child: FadeTransition(
                            opacity: contentFade,
                            child: Transform.translate(
                              offset: Offset(0, contentOffset.value),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
}
