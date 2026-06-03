import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:confetti/confetti.dart';

void appSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(message),
    ),
  );
}

OverlayEntry? _topOverlay;
Timer? _topOverlayTimer;

/// يظهر فوق كل المحتوى (حتى فوق الأوراق السفلية).
void appSnackTop(BuildContext context, String message) {
  _topOverlayTimer?.cancel();
  _topOverlay?.remove();
  _topOverlay = OverlayEntry(
    builder: (overlayContext) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(overlayContext).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                message,
                style: TextStyle(color: Theme.of(overlayContext).colorScheme.onInverseSurface),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(_topOverlay!);
  _topOverlayTimer = Timer(const Duration(seconds: 3), () {
    _topOverlay?.remove();
    _topOverlay = null;
  });
}

void lightSuccessHaptic() {
  HapticFeedback.lightImpact();
}

void mediumHaptic() {
  HapticFeedback.mediumImpact();
}

void showCelebration(BuildContext context, String message) {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black12,
    builder: (ctx) => _CelebrationDialog(message: message),
  );
}

class _CelebrationDialog extends StatefulWidget {
  final String message;
  const _CelebrationDialog({required this.message});
  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  late ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
    _controller.play();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, val, child) {
              return Transform.scale(
                scale: Curves.elasticOut.transform(val),
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      widget.message,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
