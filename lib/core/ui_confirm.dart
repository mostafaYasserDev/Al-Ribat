import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<T?> _showAppleDialog<T>(
  BuildContext context, {
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => child,
    transitionBuilder: (_, animation, __, dialogChild) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: dialogChild,
        ),
      );
    },
  );
}

Future<bool> confirmDestructiveAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
  String cancelLabel = 'إلغاء',
}) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final cardBg = theme.cardTheme.color ??
      (isDark ? const Color(0xFF111B2E) : Colors.white);

  final result = await _showAppleDialog<bool>(
    context,
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              elevation: 16,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(cancelLabel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF3B30),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(confirmLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

enum ActivityDeleteOption { skipToday, endFuture, deleteCompletely }

Future<ActivityDeleteOption?> showActivityDeleteOptions(
  BuildContext context,
  String title,
) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final cardBg = theme.cardTheme.color ??
      (isDark ? const Color(0xFF111B2E) : Colors.white);
  final innerBg = isDark
      ? const Color(0xFF0A101D)
      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
  final dividerColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

  return _showAppleDialog<ActivityDeleteOption>(
    context,
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              elevation: 16,
              shadowColor: Colors.black.withValues(alpha: 0.25),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'حذف «$title»',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'اختر كيف تريد التعامل مع هذا النشاط:',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: innerBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dividerColor, width: 0.6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _DeleteOptionRow(
                            icon: Icons.skip_next_rounded,
                            color: const Color(0xFFFF9500),
                            title: 'تخطي لليوم فقط',
                            subtitle: 'لن يظهر اليوم، وسيعود غداً',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(
                                context,
                                ActivityDeleteOption.skipToday,
                              );
                            },
                          ),
                          Divider(
                            height: 0.6,
                            thickness: 0.6,
                            indent: 52,
                            color: dividerColor,
                          ),
                          _DeleteOptionRow(
                            icon: Icons.event_busy_rounded,
                            color: const Color(0xFF007AFF),
                            title: 'إيقاف من اليوم والمستقبل',
                            subtitle: 'يُحفظ في السجل الماضي ويتوقف مستقبلاً',
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(
                                context,
                                ActivityDeleteOption.endFuture,
                              );
                            },
                          ),
                          Divider(
                            height: 0.6,
                            thickness: 0.6,
                            indent: 52,
                            color: dividerColor,
                          ),
                          _DeleteOptionRow(
                            icon: Icons.delete_forever_rounded,
                            color: const Color(0xFFFF3B30),
                            title: 'حذف نهائي',
                            subtitle: 'مسح النشاط وسجلاته بالكامل',
                            isDestructive: true,
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(
                                context,
                                ActivityDeleteOption.deleteCompletely,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
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

class _DeleteOptionRow extends StatelessWidget {
  const _DeleteOptionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDestructive ? color : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.58),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
