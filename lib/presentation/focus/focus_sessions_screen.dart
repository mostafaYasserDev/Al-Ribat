import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/active_focus_provider.dart';
import '../../application/providers.dart';
import '../../core/ui/error_view.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/work_session_item.dart';
import '../../services/motivation_quotes.dart';

part 'focus_active_session_actions.dart';
part 'focus_active_session_card.dart';
part 'focus_active_session_header.dart';
part 'focus_empty_state.dart';
part 'focus_helpers.dart';
part 'focus_session_tile.dart';
part 'focus_sessions_body.dart';
part 'focus_start_sheet.dart';
part 'focus_start_sheet_fields.dart';

class FocusSessionsScreen extends ConsumerWidget {
  const FocusSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(activeFocusProvider);
    final sessionsAsync = ref.watch(workSessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('جلسات التركيز')),
      floatingActionButton: activeSession == null
          ? FloatingActionButton.extended(
              heroTag: 'focus_fab',
              onPressed: () {
                HapticFeedback.lightImpact();
                _openFocusStartSheet(context, ref);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('جلسة جديدة'),
            )
          : null,
      body: Column(
        children: [
          if (activeSession != null)
            _buildActiveFocusCard(context, ref, activeSession),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) => _buildFocusSessionsList(
                context: context,
                ref: ref,
                sessions: sessions,
                hasActiveSession: activeSession != null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorView(
                error: e,
                onRetry: () => ref.invalidate(workSessionsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
