import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/ui/error_view.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import 'package:al_ribat/services/motivation_quotes.dart';
import '../application/active_focus_notifier.dart';
import '../domain/active_focus_state.dart';
import '../domain/work_session_item.dart';
import 'widgets/focus_ambient_sound_sheet.dart';
import 'widgets/focus_completion_sheet.dart';
import 'widgets/focus_full_screen_zen.dart';
import 'widgets/focus_linked_task_card.dart';
import 'widgets/focus_mode_selector.dart';
import 'widgets/focus_session_tile.dart';
import 'widgets/focus_zen_dial.dart';

class FocusSessionsScreen extends ConsumerStatefulWidget {
  const FocusSessionsScreen({super.key});

  @override
  ConsumerState<FocusSessionsScreen> createState() =>
      _FocusSessionsScreenState();
}

class _FocusSessionsScreenState extends ConsumerState<FocusSessionsScreen> {
  FocusSessionMode _selectedMode = FocusSessionMode.untilPrayer;
  int _selectedMinutes = 25;
  ActivityItem? _linkedActivity;
  late final String _dailyQuote;

  @override
  void initState() {
    super.initState();
    _dailyQuote = MotivationQuotes.randomLine();
  }

  PrayerTime _nextPrayer(PrayerSchedule schedule, PrayerPhase currentPhase) {
    final idx = schedule.today.indexWhere((p) => p.phase == currentPhase);
    if (idx >= 0 && idx < schedule.today.length - 1) {
      return schedule.today[idx + 1];
    }
    return schedule.tomorrowFajr;
  }

  void _onStartFocus(PrayerSchedule? schedule, PrayerPhase currentPhase) {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(activeFocusProvider.notifier);
    final taskTitle = _linkedActivity?.title;

    switch (_selectedMode) {
      case FocusSessionMode.untilPrayer:
        if (schedule != null) {
          final next = _nextPrayer(schedule, currentPhase);
          notifier.startUntilPrayer(
            title: taskTitle != null
                ? 'رباط $taskTitle'
                : 'الرباط حتى ${next.phase.arabicName}',
            nextPrayerTime: next.time,
            linkedActivityId: _linkedActivity?.id,
            linkedActivityTitle: taskTitle,
          );
        } else {
          notifier.startSession(
            title: taskTitle ?? 'جلسة تركيز',
            plannedMinutes: _selectedMinutes,
            mode: FocusSessionMode.customTimer,
            linkedActivityId: _linkedActivity?.id,
            linkedActivityTitle: taskTitle,
          );
        }
        break;

      case FocusSessionMode.pomodoro:
        notifier.startPomodoro(
          title: taskTitle != null ? 'بومودورو: $taskTitle' : 'بومودورو تركيز',
          workMinutes: 25,
          linkedActivityId: _linkedActivity?.id,
          linkedActivityTitle: taskTitle,
        );
        break;

      case FocusSessionMode.customTimer:
        notifier.startSession(
          title: taskTitle ?? 'جلسة تركيز',
          plannedMinutes: _selectedMinutes,
          mode: FocusSessionMode.customTimer,
          linkedActivityId: _linkedActivity?.id,
          linkedActivityTitle: taskTitle,
        );
        break;

      case FocusSessionMode.openStopwatch:
        notifier.startOpenStopwatch(
          title: taskTitle ?? 'تركيز مفتوح',
          linkedActivityId: _linkedActivity?.id,
          linkedActivityTitle: taskTitle,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeFocusProvider);
    final sessionsAsync = ref.watch(workSessionsProvider);
    final scheduleAsync = ref.watch(prayerScheduleProvider);
    final dayState = ref.watch(dayStateProvider);
    final schedule = scheduleAsync.valueOrNull;

    // Listen for completion to pop up the celebration dialog
    ref.listen<WorkSessionItem?>(lastCompletedSessionProvider, (prev, next) {
      if (next != null) {
        FocusCompletionSheet.show(context, next);
        ref.read(lastCompletedSessionProvider.notifier).state = null;
      }
    });

    final nextPrayer = schedule == null
        ? null
        : _nextPrayer(schedule, dayState.currentPrayerPhase);
    final remainingPrayerMin =
        nextPrayer?.time.difference(DateTime.now()).inMinutes.clamp(1, 1440);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSessionActive = activeSession != null;

    // Dial Display info
    int dialMinutes;
    String displayTime;
    double progress;
    bool isPaused = false;

    if (isSessionActive) {
      isPaused = activeSession.isPaused;
      dialMinutes = activeSession.plannedMinutes;
      if (activeSession.mode == FocusSessionMode.openStopwatch) {
        final m = activeSession.elapsedSeconds ~/ 60;
        final s = activeSession.elapsedSeconds % 60;
        displayTime =
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        progress = 1.0;
      } else {
        final totalSec =
            (activeSession.plannedMinutes * 60).clamp(1, double.infinity);
        final m = activeSession.remainingSeconds ~/ 60;
        final s = activeSession.remainingSeconds % 60;
        displayTime =
            '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        progress = (activeSession.elapsedSeconds / totalSec).clamp(0.0, 1.0);
      }
    } else {
      if (_selectedMode == FocusSessionMode.untilPrayer &&
          remainingPrayerMin != null) {
        dialMinutes = remainingPrayerMin;
      } else if (_selectedMode == FocusSessionMode.pomodoro) {
        dialMinutes = 25;
      } else if (_selectedMode == FocusSessionMode.openStopwatch) {
        dialMinutes = 0;
      } else {
        dialMinutes = _selectedMinutes;
      }
      displayTime = _selectedMode == FocusSessionMode.openStopwatch
          ? '00:00'
          : '$dialMinutes:00';
      progress = (dialMinutes / 120.0).clamp(0.0, 1.0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('رواق التركيز والرباط',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.spatial_audio_rounded),
            tooltip: 'الأجواء الصوتية',
            onPressed: () => FocusAmbientSoundSheet.show(context),
          ),
          if (isSessionActive)
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded),
              tooltip: 'وضع شاشة المكتب الغامرة',
              onPressed: () => FocusFullScreenZen.open(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main Body
          ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              const SizedBox(height: 8),

              // Mode Selector (Disabled when session is active)
              if (!isSessionActive) ...[
                FocusModeSelector(
                  selectedMode: _selectedMode,
                  onSelect: (mode) {
                    setState(() {
                      _selectedMode = mode;
                      if (mode == FocusSessionMode.untilPrayer &&
                          remainingPrayerMin != null) {
                        _selectedMinutes = remainingPrayerMin;
                      } else if (mode == FocusSessionMode.pomodoro) {
                        _selectedMinutes = 25;
                      }
                    });
                  },
                  remainingUntilPrayerMinutes: remainingPrayerMin,
                  nextPrayerName: nextPrayer?.phase.arabicName,
                ),
                const SizedBox(height: 14),
              ],

              // Linked Task Card
              FocusLinkedTaskCard(
                selectedActivity: isSessionActive
                    ? (activeSession.linkedActivityTitle != null
                        ? ActivityItem(
                            id: activeSession.linkedActivityId ?? '',
                            title: activeSession.linkedActivityTitle!,
                            createdAt: activeSession.startedAt,
                          )
                        : null)
                    : _linkedActivity,
                onSelectActivity: (act) =>
                    setState(() => _linkedActivity = act),
                onClearActivity: () => setState(() => _linkedActivity = null),
                disabled: isSessionActive,
              ),

              const SizedBox(height: 20),

              // Interactive Zen Dial
              FocusZenDial(
                minutes: dialMinutes,
                onChanged: (newMin) => setState(() {
                  _selectedMinutes = newMin;
                  _selectedMode = FocusSessionMode.customTimer;
                }),
                isActive: isSessionActive,
                progress: progress,
                displayTime: displayTime,
                isPaused: isPaused,
              ),

              const SizedBox(height: 24),

              // Session Action Controls
              Center(
                child: isSessionActive
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              if (activeSession.isPaused) {
                                ref
                                    .read(activeFocusProvider.notifier)
                                    .resumeSession();
                              } else {
                                ref
                                    .read(activeFocusProvider.notifier)
                                    .pauseSession();
                              }
                            },
                            icon: Icon(isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded),
                            label: Text(isPaused ? 'استئناف' : 'إيقاف مؤقت'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () async {
                              await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('إنهاء الجلسة'),
                                  content: const Text(
                                      'هل ترغب في حفظ الدقائق المنجزة حتى الآن أم إلغاء الجلسة؟'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx, false);
                                        ref
                                            .read(activeFocusProvider.notifier)
                                            .cancelSession();
                                      },
                                      child: const Text('إلغاء دون حفظ',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(ctx, true);
                                        ref
                                            .read(activeFocusProvider.notifier)
                                            .savePartial();
                                      },
                                      child: const Text('حفظ واكتمال'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: const Text('إنهاء'),
                          ),
                        ],
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 36, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          elevation: 3,
                        ),
                        onPressed: () => _onStartFocus(
                            schedule, dayState.currentPrayerPhase),
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Text(
                          'ابدأ التركيز الآن',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Motivational Quote
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _dailyQuote,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),

          // Draggable Bottom Sheet for Past Focus History
          DraggableScrollableSheet(
            initialChildSize: 0.16,
            minChildSize: 0.12,
            maxChildSize: 0.72,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سجل جلسات التركيز السابقة',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        sessionsAsync.maybeWhen(
                          data: (list) {
                            final totalMinutes = list.fold<int>(
                                0, (acc, s) => acc + s.actualMinutes);
                            return Text(
                              'إجمالي اليوم: ${totalMinutes ~/ 60}س ${totalMinutes % 60}د',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    sessionsAsync.when(
                      data: (sessions) {
                        if (sessions.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child:
                                Center(child: Text('لا توجد جلسات مسجلة بعد')),
                          );
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sessions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              FocusSessionTile(session: sessions[i]),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => AppErrorView(
                        error: e,
                        onRetry: () => ref.invalidate(workSessionsProvider),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
