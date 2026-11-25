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
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const FocusHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(workSessionsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سجل جلسات التركيز',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'اليوم: ${FocusTimeFormatter.formatSecondsReadable(todaySeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: sessionsAsync.when(
                    data: (sessions) {
                      if (sessions.isEmpty) {
                        return const Center(
                          child: Text('لا توجد جلسات مسجلة بعد'),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final item = sessions[i];
                          return FocusSessionTile(
                            session: item,
                            onDelete: () => ref
                                .read(workSessionsProvider.notifier)
                                .deleteSession(item.id),
                          );
                        },
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
          );
        },
      ),
    );
  }
}
