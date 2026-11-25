import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_moods.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import '../../application/active_focus_notifier.dart';
import '../../domain/focus_time_formatter.dart';
import '../../domain/work_session_item.dart';
import 'focus_linked_task_card.dart';

class FocusCompletionSheet extends ConsumerStatefulWidget {
  const FocusCompletionSheet({super.key, required this.session});

  final WorkSessionItem session;

  static void show(BuildContext context, WorkSessionItem session) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FocusCompletionSheet(session: session),
    );
  }

  @override
  ConsumerState<FocusCompletionSheet> createState() =>
      _FocusCompletionSheetState();
}

class _FocusCompletionSheetState extends ConsumerState<FocusCompletionSheet> {
  late final ConfettiController _confettiController;
  final _reflectionController = TextEditingController();
  String? _selectedMood;
  ActivityItem? _postLinkedActivity;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    if (_postLinkedActivity != null &&
        widget.session.linkedActivityTitle == null) {
      await ref
          .read(activeFocusProvider.notifier)
          .linkActivityToCompletedSession(
            widget.session,
            _postLinkedActivity!,
          );
    }

    final text = _reflectionController.text.trim();
    if (text.isNotEmpty || _selectedMood != null) {
      final prayerName =
          ref.read(dayStateProvider).currentPrayerPhase.arabicName;
      await ref.read(reflectionsProvider.notifier).add(
            text.isEmpty ? 'تم إنجاز جلسة تركيز مباركة' : text,
            mood: _selectedMood,
            prayerPhaseName: prayerName,
            linkedContextTitle: 'تركيز: ${widget.session.name}',
          );
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final s = widget.session;
    final actualSec = s.endedAt.difference(s.startedAt).inSeconds;
    final durationLabel = FocusTimeFormatter.formatSecondsReadable(actualSec);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.teal,
              Colors.amber,
              Colors.blue
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 36),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.completed
                        ? 'مبارك! اكتملت الجلسة بحمد الله'
                        : 'تم حفظ الجلسة بنجاح',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'أنجزت $durationLabel من التركيز في "${s.name}"',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  if (s.linkedActivityTitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '✓ مرتبطة بالمهمة: ${s.linkedActivityTitle!}',
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    FocusLinkedTaskCard(
                      selectedActivity: _postLinkedActivity,
                      buttonLabel: 'ربط هذه الجلسة بمهمة من اليوم',
                      onSelectActivity: (act) =>
                          setState(() => _postLinkedActivity = act),
                      onClearActivity: () =>
                          setState(() => _postLinkedActivity = null),
                    ),
                    if (_postLinkedActivity != null &&
                        _postLinkedActivity!.isMeasurable &&
                        !ActiveFocusNotifier.isTimeMeasuredActivity(
                            _postLinkedActivity!)) ...[
                      const SizedBox(height: 6),
                      Text(
                        'ملاحظة: هذه المهمة تُقاس بـ (${_postLinkedActivity!.goalUnit ?? "وحدات"})؛ سيتم توثيق ارتباط الجلسة بها في السجل دون تعديل عداد وحداتها.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'كيف كان شعورك خلال هذه الجلسة؟ (اختياري)',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: AppMoods.options.take(5).map((m) {
                      final selected = _selectedMood == m.label;
                      return ChoiceChip(
                        avatar: Icon(m.icon, size: 16, color: m.color),
                        label: Text(m.label),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedMood = m.label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reflectionController,
                    decoration: const InputDecoration(
                      hintText: 'سجل خاطرة أو فكرة خطرت ببالك أثناء التركيز...',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saveReflection,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('حفظ واكتمال'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
