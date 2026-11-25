import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/domain/entities/prayer_schedule.dart';
import 'package:al_ribat/domain/entities/prayer_time.dart';
import 'package:al_ribat/features/activities/domain/activity_item.dart';
import 'package:al_ribat/features/prayer/domain/prayer_phase.dart';
import 'package:al_ribat/services/motivation_quotes.dart';
import '../application/active_focus_notifier.dart';
import '../domain/active_focus_state.dart';
import '../domain/focus_time_formatter.dart';
import '../domain/work_session_item.dart';
import 'widgets/focus_completion_sheet.dart';
import 'widgets/focus_full_screen_zen.dart';
import 'widgets/focus_history_sheet.dart';
import 'widgets/focus_linked_task_card.dart';
import 'widgets/focus_mode_selector.dart';
import 'widgets/focus_timer_card.dart';

class FocusSessionsScreen extends ConsumerStatefulWidget {
  const FocusSessionsScreen({super.key});

  @override
  ConsumerState<FocusSessionsScreen> createState() =>
      _FocusSessionsScreenState();
}

class _FocusSessionsScreenState extends ConsumerState<FocusSessionsScreen> {
  FocusSessionMode _selectedMode = FocusSessionMode.untilPrayer;
  int _selectedMinutes = 25;
  bool _isPomodoroPreset = false;
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
        if (_isPomodoroPreset) {
          notifier.startPomodoro(
            title:
                taskTitle != null ? 'بومودورو: $taskTitle' : 'بومودورو تركيز',
            workMinutes: 25,
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
    final scheduleAsync = ref.watch(prayerScheduleProvider);
    final dayState = ref.watch(dayStateProvider);
    final schedule = scheduleAsync.valueOrNull;

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

    String displayTime;
    double progress;
    bool isPaused = false;
    int timerMinutes;

    if (isSessionActive) {
      isPaused = activeSession.isPaused;
      timerMinutes = activeSession.plannedMinutes;
      final totalSec =
          (activeSession.plannedMinutes * 60).clamp(1, double.infinity);
      final secondsToDisplay =
          activeSession.mode == FocusSessionMode.openStopwatch
              ? activeSession.elapsedSeconds
              : activeSession.remainingSeconds;
      displayTime = FocusTimeFormatter.formatCountdown(secondsToDisplay);
      progress = activeSession.mode == FocusSessionMode.openStopwatch
          ? 1.0
          : (activeSession.elapsedSeconds / totalSec).clamp(0.0, 1.0);
    } else {
      if (_selectedMode == FocusSessionMode.untilPrayer &&
          remainingPrayerMin != null) {
        timerMinutes = remainingPrayerMin;
      } else if (_selectedMode == FocusSessionMode.openStopwatch) {
        timerMinutes = 0;
      } else {
        timerMinutes = _selectedMinutes;
      }
      displayTime = _selectedMode == FocusSessionMode.openStopwatch
          ? '00:00'
          : FocusTimeFormatter.formatCountdown(timerMinutes * 60);
      progress = 0.0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'التركيز والرباط',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل الجلسات السابقة',
            onPressed: () => FocusHistorySheet.show(context),
          ),
          if (isSessionActive)
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded),
              tooltip: 'وضع شاشة المكتب الكاملة',
              onPressed: () => FocusFullScreenZen.open(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 36),
        children: [
          if (!isSessionActive) ...[
            FocusModeSelector(
              selectedMode: _selectedMode,
              onSelect: (mode) {
                setState(() {
                  _selectedMode = mode;
                  if (mode != FocusSessionMode.customTimer) {
                    _isPomodoroPreset = false;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
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
            onSelectActivity: (act) => setState(() => _linkedActivity = act),
            onClearActivity: () => setState(() => _linkedActivity = null),
            disabled: isSessionActive,
          ),

          const SizedBox(height: 18),

          // Wide Digital Timer Card
          FocusTimerCard(
            selectedMode: isSessionActive ? activeSession.mode : _selectedMode,
            selectedMinutes: timerMinutes,
            isPomodoroPreset: _isPomodoroPreset,
            displayTime: displayTime,
            isActive: isSessionActive,
            isPaused: isPaused,
            progress: progress,
            activeTitle: activeSession?.title,
            nextPrayerName: nextPrayer?.phase.arabicName,
            nextPrayerTime: nextPrayer?.time,
            remainingPrayerMinutes: remainingPrayerMin,
            onSelectPreset: (mins, {bool isPomodoro = false}) {
              setState(() {
                _selectedMinutes = mins;
                _isPomodoroPreset = isPomodoro;
                _selectedMode = isPomodoro
                    ? FocusSessionMode.pomodoro
                    : FocusSessionMode.customTimer;
              });
            },
            onDurationChanged: (mins) {
              setState(() {
                _selectedMinutes = mins;
                _isPomodoroPreset = false;
                _selectedMode = FocusSessionMode.customTimer;
              });
            },
          ),

          const SizedBox(height: 24),

          // Action Controls
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
                              borderRadius: BorderRadius.circular(18)),
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
                              borderRadius: BorderRadius.circular(18)),
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
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 2,
                    ),
                    onPressed: () =>
                        _onStartFocus(schedule, dayState.currentPrayerPhase),
                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    label: const Text(
                      'ابدأ التركيز الآن',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),

          const SizedBox(height: 28),

          // Motivational Quote
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                _dailyQuote,
                style: TextStyle(
                  fontSize: 12.5,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
