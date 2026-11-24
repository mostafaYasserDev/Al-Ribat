part of 'focus_sessions_screen.dart';

Widget _buildActiveFocusHeader(
  BuildContext context,
  ActiveFocusState activeSession,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        activeSession.isPaused
            ? Icons.pause_circle_filled_rounded
            : Icons.timer_rounded,
        color: Theme.of(context).colorScheme.primary,
        size: 40,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeSession.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              activeSession.isPaused
                  ? 'موقوفة مؤقتاً · المتبقي: ${_formatRemain(activeSession.remainingSeconds)}'
                  : 'جلسة جارية · المتبقي: ${_formatRemain(activeSession.remainingSeconds)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      Text(
        _formatRemain(activeSession.remainingSeconds),
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    ],
  );
}
