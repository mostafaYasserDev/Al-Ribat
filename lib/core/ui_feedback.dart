import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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
