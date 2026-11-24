import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/ui/error_view.dart';
import 'package:al_ribat/services/motivation_quotes.dart';
import '../application/active_focus_notifier.dart';
import '../domain/work_session_item.dart';
import 'widgets/focus_active_session_card.dart';
import 'widgets/focus_session_tile.dart';
import 'widgets/focus_start_sheet.dart';

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
                FocusStartSheet.show(context, ref);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('جلسة جديدة'),
            )
          : null,
      body: Column(
        children: [
          if (activeSession != null)
            FocusActiveSessionCard(activeSession: activeSession),
          Expanded(
            child: sessionsAsync.when(
              data: (sessions) => _buildList(context, ref, sessions),
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

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<WorkSessionItem> sessions,
  ) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.center_focus_strong,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'ابدأ جلسة تركيزٍ عميقة.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                MotivationQuotes.randomLine(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  FocusStartSheet.show(context, ref);
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('بدء جلسة جديدة'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => FocusSessionTile(session: sessions[i]),
    );
  }
}
