part of 'focus_sessions_screen.dart';

Widget _buildActiveFocusCard(
  BuildContext context,
  WidgetRef ref,
  ActiveFocusState activeSession,
) {
  return Card(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        width: 1.5,
      ),
    ),
    color:
        Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActiveFocusHeader(context, activeSession),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (activeSession.plannedMinutes * 60 -
                      activeSession.remainingSeconds) /
                  (activeSession.plannedMinutes * 60).clamp(1, double.infinity),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          _buildActiveFocusActions(context, ref, activeSession),
        ],
      ),
    ),
  );
}
