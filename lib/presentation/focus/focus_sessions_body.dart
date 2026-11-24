part of 'focus_sessions_screen.dart';

Widget _buildFocusSessionsList({
  required BuildContext context,
  required WidgetRef ref,
  required List<WorkSessionItem> sessions,
  required bool hasActiveSession,
}) {
  final sorted = [...sessions]
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  if (sorted.isEmpty && !hasActiveSession) {
    return _FocusEmptyState(
      onStart: () => _openFocusStartSheet(context, ref),
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
    itemCount: sorted.length,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (context, i) => _FocusSessionTile(session: sorted[i]),
  );
}
