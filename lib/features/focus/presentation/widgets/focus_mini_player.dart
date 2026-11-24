import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/active_focus_notifier.dart';
import '../../domain/active_focus_state.dart';
import 'focus_full_screen_zen.dart';

class FocusMiniPlayer extends ConsumerWidget {
  const FocusMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeFocusProvider);
    if (active == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalSec = (active.plannedMinutes * 60).clamp(1, double.infinity);
    final progress = active.mode == FocusSessionMode.openStopwatch
        ? 1.0
        : (active.elapsedSeconds / totalSec).clamp(0.0, 1.0);

    final m = active.mode == FocusSessionMode.openStopwatch
        ? active.elapsedSeconds ~/ 60
        : active.remainingSeconds ~/ 60;
    final s = active.mode == FocusSessionMode.openStopwatch
        ? active.elapsedSeconds % 60
        : active.remainingSeconds % 60;
    final displayTime =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: active.isPaused
              ? Colors.orange.withValues(alpha: 0.5)
              : colorScheme.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => FocusFullScreenZen.open(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        color: active.isPaused
                            ? Colors.orange
                            : colorScheme.primary,
                        backgroundColor:
                            colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    Icon(
                      active.isPaused
                          ? Icons.pause_rounded
                          : (active.mode == FocusSessionMode.untilPrayer
                              ? Icons.mosque_rounded
                              : Icons.timer_rounded),
                      size: 16,
                      color:
                          active.isPaused ? Colors.orange : colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        active.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        active.isPaused
                            ? 'موقوفة مؤقتاً · انقر للتكبير'
                            : (active.linkedActivityTitle != null
                                ? '${active.linkedActivityTitle!} · $displayTime'
                                : 'جلسة تركيز · $displayTime'),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  displayTime,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        active.isPaused ? Colors.orange : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    active.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    size: 22,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    if (active.isPaused) {
                      ref.read(activeFocusProvider.notifier).resumeSession();
                    } else {
                      ref.read(activeFocusProvider.notifier).pauseSession();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
