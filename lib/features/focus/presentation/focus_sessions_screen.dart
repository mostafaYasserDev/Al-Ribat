import 'dart:async';

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
import 'widgets/focus_full_screen_zen.dart';
import 'widgets/focus_history_sheet.dart';
import 'widgets/focus_linked_task_card.dart';
import 'widgets/focus_mode_selector.dart';
import 'widgets/focus_session_controls.dart';
import 'widgets/focus_timer_card.dart';

class FocusSessionsScreen extends ConsumerStatefulWidget {
  const FocusSessionsScreen({super.key});

  @override
  ConsumerState<FocusSessionsScreen> createState() =>
      _FocusSessionsScreenState();
}

class _FocusSessionsScreenState extends ConsumerState<FocusSessionsScreen> {
  FocusSessionMode _selectedMode = FocusSessionMode.untilPrayer;
  int _selectedSeconds = 25 * 60;
  bool _isPomodoroPreset = false;
  ActivityItem? _linkedActivity;
  String? _linkedProjectName;
  late final String _dailyQuote;
  Timer? _prayerRefreshTimer;

  @override
  void initState() {
    super.initState();
    _dailyQuote = MotivationQuotes.randomLine();
    _prayerRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted &&
            _selectedMode == FocusSessionMode.untilPrayer &&
            ref.read(activeFocusProvider) == null) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _prayerRefreshTimer?.cancel();
    super.dispose();
  }

  PrayerTime _nextPrayer(PrayerSchedule schedule) {
    final now = DateTime.now();
    for (final p in schedule.today) {
      if (p.time.isAfter(now)) {
        return p;
      }
    }
    return schedule.tomorrowFajr;
  }

  void _onStartFocus(PrayerSchedule? schedule) {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(activeFocusProvider.notifier);
    final taskTitle = _linkedActivity?.title;
    final projectTitle = _linkedProjectName;
    final displayContext = taskTitle ?? projectTitle;

    switch (_selectedMode) {
      case FocusSessionMode.untilPrayer:
        if (schedule != null) {
          final next = _nextPrayer(schedule);
          notifier.startUntilPrayer(
            title: displayContext != null
                ? 'رباط $displayContext'
                : 'الرباط حتى ${next.phase.arabicName}',
            nextPrayerTime: next.time,
            linkedActivityId: _linkedActivity?.id,
            linkedActivityTitle: taskTitle,
            projectName: projectTitle,
          );
        } else {
          notifier.startSession(
            title: displayContext ?? 'جلسة تركيز',
            plannedMinutes: (_selectedSeconds / 60).ceil(),
            plannedSeconds: _selectedSeconds,
            mode: FocusSessionMode.customTimer,
            linkedActivityId: _linkedActivity?.id,
            linkedActivityTitle: taskTitle,
            projectName: projectTitle,
          );
        }
        break;

      case FocusSessionMode.pomodoro:
        notifier.startPomodoro(
          title: displayContext != null
              ? 'بومودورو: $displayContext'
              : 'بومودورو تركيز',
          workMinutes: 25,
          linkedActivityId: _linkedActivity?.id,
          linkedActivityTitle: taskTitle,
          projectName: projectTitle,
        );
        break;

      case FocusSessionMode.customTimer:
        if (_isPomodoroPreset) {
          notifier.startPomodoro(
            title: displayContext != null
                ? 'بومودورو: $displayContext'
                : 'بومودورو تركيز',
            workMinutes: 25,
            linkedActivityId: _linkedActivity?.id,
            linkedActivityTitle: taskTitle,
            projectName: projectTitle,
          );
        } else {
          notifier.startSession(
            title: displayContext ?? 'جلسة تركيز',
            plannedMinutes: (_selectedSeconds / 60).ceil(),
            plannedSeconds: _selectedSeconds,
            mode: FocusSessionMode.customTimer,
            linkedActivityId: _linkedActivity?.id,
            linkedActivityTitle: taskTitle,
            projectName: projectTitle,
          );
        }
        break;

      case FocusSessionMode.openStopwatch:
        notifier.startOpenStopwatch(
          title: displayContext ?? 'تركيز مفتوح',
          linkedActivityId: _linkedActivity?.id,
          linkedActivityTitle: taskTitle,
          projectName: projectTitle,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeFocusProvider);
    final scheduleAsync = ref.watch(todayPrayerScheduleProvider);
    final schedule = scheduleAsync.valueOrNull;

    final nextPrayer = schedule == null ? null : _nextPrayer(schedule);
    final remainingPrayerSec =
        nextPrayer?.time.difference(DateTime.now()).inSeconds.clamp(1, 86400);
    final remainingPrayerMin = remainingPrayerSec != null
        ? FocusTimeFormatter.roundToNearestMinute(remainingPrayerSec)
        : null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isSessionActive = activeSession != null;

    String displayTime;
    double progress;
    bool isPaused = false;
    int timerSeconds;

    if (isSessionActive) {
      isPaused = activeSession.isPaused;
      timerSeconds = activeSession.plannedSeconds;
      final totalSec = activeSession.plannedSeconds.clamp(1, double.infinity);
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
        timerSeconds = remainingPrayerMin * 60;
      } else if (_selectedMode == FocusSessionMode.openStopwatch) {
        timerSeconds = 0;
      } else {
        timerSeconds = _selectedSeconds;
      }
      displayTime = _selectedMode == FocusSessionMode.openStopwatch
          ? '00:00'
          : FocusTimeFormatter.formatCountdown(timerSeconds);
      progress = 0.0;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: 96,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              actions: [
                if (isSessionActive)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: _HeaderPillButton(
                      icon: Icons.fullscreen_rounded,
                      tooltip: 'وضع ملء الشاشة',
                      onTap: () => FocusFullScreenZen.open(context),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: _HeaderPillButton(
                    icon: Icons.history_rounded,
                    tooltip: 'سجل الجلسات السابقة',
                    onTap: () => FocusHistorySheet.show(context),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 20,
                  bottom: 14,
                  end: 96,
                ),
                centerTitle: false,
                title: Text(
                  'التركيز والرباط',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.6),
                child: Container(
                  height: 0.6,
                  color: colorScheme.onSurface
                      .withValues(alpha: isDark ? 0.08 : 0.06),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 14, bottom: 36),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: !isSessionActive
                        ? Column(
                            children: [
                              FocusModeSelector(
                                selectedMode: _selectedMode,
                                nextPrayerName: nextPrayer?.phase.arabicName,
                                nextPrayerTime: nextPrayer?.time,
                                remainingPrayerMinutes: remainingPrayerMin,
                                onSelect: (mode) {
                                  setState(() {
                                    _selectedMode = mode;
                                    if (mode != FocusSessionMode.customTimer) {
                                      _isPomodoroPreset = false;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
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
                    selectedProjectName: isSessionActive
                        ? activeSession.projectName
                        : _linkedProjectName,
                    onSelectActivity: (act) {
                      if (isSessionActive) {
                        ref
                            .read(activeFocusProvider.notifier)
                            .linkActivity(act.id, act.title);
                      } else {
                        setState(() {
                          _linkedActivity = act;
                          _linkedProjectName = null;
                        });
                      }
                    },
                    onSelectProject: (projectName) {
                      if (isSessionActive) {
                        ref
                            .read(activeFocusProvider.notifier)
                            .linkProject(projectName);
                      } else {
                        setState(() {
                          _linkedProjectName = projectName;
                          _linkedActivity = null;
                        });
                      }
                    },
                    onClearActivity: () {
                      if (isSessionActive) {
                        ref
                            .read(activeFocusProvider.notifier)
                            .clearLinkedActivity();
                      } else {
                        setState(() {
                          _linkedActivity = null;
                          _linkedProjectName = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  FocusTimerCard(
                    selectedMode:
                        isSessionActive ? activeSession.mode : _selectedMode,
                    selectedSeconds: timerSeconds,
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
                        _selectedSeconds = mins * 60;
                        _isPomodoroPreset = isPomodoro;
                        _selectedMode = isPomodoro
                            ? FocusSessionMode.pomodoro
                            : FocusSessionMode.customTimer;
                      });
                    },
                    onDurationSecondsChanged: (secs) {
                      setState(() {
                        _selectedSeconds = secs;
                        _isPomodoroPreset = false;
                        _selectedMode = FocusSessionMode.customTimer;
                      });
                    },
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOutCubic,
                      child: isSessionActive
                          ? FocusActiveControls(
                              key: const ValueKey('active_controls'),
                              isPaused: isPaused,
                              onTogglePause: () {
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
                              onFinish: () => _showFinishSessionDialog(context),
                            )
                          : _FocusStartPillButton(
                              key: const ValueKey('idle_controls'),
                              onTap: () => _onStartFocus(schedule),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _TodayFocusMiniSummary(
                    onTapHistory: () => FocusHistorySheet.show(context),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      _dailyQuote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFinishSessionDialog(BuildContext context) async {
    final action = await showFinishSessionSheet(context);
    if (action == null || !mounted) return;
    final notifier = ref.read(activeFocusProvider.notifier);
    if (action == FinishSessionAction.saveAndFinish) {
      notifier.savePartial();
    } else {
      notifier.cancelSession();
    }
  }
}

class _FocusStartPillButton extends StatefulWidget {
  const _FocusStartPillButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<_FocusStartPillButton> createState() => _FocusStartPillButtonState();
}

class _FocusStartPillButtonState extends State<_FocusStartPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentEnd = Color.lerp(colorScheme.primary, Colors.teal, 0.35) ??
        colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          height: 54,
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            gradient: LinearGradient(
              colors: [colorScheme.primary, accentEnd],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
            ),
            shadows: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ابدأ التركيز الآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayFocusMiniSummary extends ConsumerWidget {
  const _TodayFocusMiniSummary({required this.onTapHistory});

  final VoidCallback onTapHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workSessionsProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todaySessions =
        sessions.where((s) => !s.startedAt.isBefore(todayStart)).toList();
    final totalMinutes = todaySessions.fold<int>(
      0,
      (sum, item) => sum + item.actualMinutes,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: isDark
            ? const Color(0xFF111B2E).withValues(alpha: 0.72)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTapHistory();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.onSurface
                    .withValues(alpha: isDark ? 0.08 : 0.06),
                width: 0.7,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    todaySessions.isEmpty
                        ? 'لم تبدأ جلسة تركيز اليوم بعد'
                        : 'إنجاز اليوم: ${todaySessions.length} جلسات · $totalMinutes د تركيز',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.78),
                    ),
                  ),
                ),
                Text(
                  'السجل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_left_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderPillButton extends StatelessWidget {
  const _HeaderPillButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark
            ? const Color(0xFF152036)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
