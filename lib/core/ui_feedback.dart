import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'errors/app_failure.dart';
import 'ui/celebration_dialog.dart';

/// رسالة تنبيه عائمة متكيفة مع ثيم التطبيق بأسلوب Telegram × Apple.
void appSnack(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final colorScheme = theme.colorScheme;
  final accent = isError ? colorScheme.error : colorScheme.primary;
  final bgColor =
      isDark ? const Color(0xFF152036) : Colors.white.withValues(alpha: 0.96);

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : accent.withValues(alpha: 0.18),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.09),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_rounded,
                  size: 17,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                Material(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      messenger.hideCurrentSnackBar();
                      onAction();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      child: Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// يعرض الخطأ بصيغة المستخدم، وليس نص الاستثناء التقني.
void appError(BuildContext context, Object error, {String? fallback}) {
  appSnack(
    context,
    AppFailure.from(error, fallback: fallback).userMessage,
    isError: true,
  );
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
