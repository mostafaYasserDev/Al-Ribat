import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'errors/app_failure.dart';
import 'ui/celebration_dialog.dart';

/// رسالة قصيرة أسفل الشاشة. تبقى الواجهة الحالية دون تغيير.
void appSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Text(message),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            )
          : null,
    ),
  );
}

/// يعرض الخطأ بصيغة المستخدم، وليس نص الاستثناء التقني.
void appError(BuildContext context, Object error, {String? fallback}) {
  appSnack(context, AppFailure.from(error, fallback: fallback).userMessage);
}

void lightSuccessHaptic() => HapticFeedback.lightImpact();

void mediumHaptic() => HapticFeedback.mediumImpact();

void showCelebration(BuildContext context, String message) {
  HapticFeedback.heavyImpact();
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black12,
    builder: (_) => CelebrationDialog(message: message),
  );
}
