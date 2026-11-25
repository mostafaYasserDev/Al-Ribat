import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/ui/error_view.dart';
import '../../domain/focus_time_formatter.dart';
import 'focus_session_tile.dart';

class FocusHistorySheet extends ConsumerWidget {
  const FocusHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FocusHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(workSessionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final sheetBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final now = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Material(
              color: sheetBg,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سجل جلسات التركيز',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        sessionsAsync.maybeWhen(
                          data: (list) {
                            final todaySeconds = list
                                .where((s) =>
                                    s.startedAt.year == now.year &&
                                    s.startedAt.month == now.month &&
                                    s.startedAt.day == now.day)
                                .fold<int>(
                                  0,
                                  (acc, s) =>
                                      acc +
                                      s.endedAt
                                          .difference(s.startedAt)
                                          .inSeconds
                                          .clamp(0, 86400),
                                );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'اليوم: ${FocusTimeFormatter.formatSecondsReadable(todaySeconds)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 0.6,
                    thickness: 0.6,
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    child: sessionsAsync.when(
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.history_rounded,
                                    size: 30,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'لا توجد جلسات مسجلة بعد',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ابدأ أول جلسة تركيز لتظهر هنا.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: isDark ? 0.08 : 0.06),
                                  width: 0.7,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var i = 0; i < sessions.length; i++) ...[
                                    FocusSessionTile(
                                      session: sessions[i],
                                      onDelete: () => ref
                                          .read(workSessionsProvider.notifier)
                                          .deleteSession(sessions[i].id),
                                    ),
                                    if (i < sessions.length - 1)
                                      Divider(
                                        height: 0.6,
                                        thickness: 0.6,
                                        indent: 58,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.08),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => AppErrorView(
                        error: e,
                        onRetry: () => ref.invalidate(workSessionsProvider),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
