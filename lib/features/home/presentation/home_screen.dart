import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../application/providers.dart';
import '../../../core/constants/prayer_phase.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../../../domain/entities/activity_item.dart';
import '../../../domain/entities/day_state.dart';
import '../../../domain/entities/prayer_schedule.dart';
import '../../../domain/entities/prayer_time.dart';
import '../../../presentation/stats/stats_screen.dart';
import '../../../presentation/widgets/add_activity_sheet.dart';
import '../../../services/motivation_quotes.dart';
import 'widgets/home_activities_sections.dart';
import 'widgets/home_date_pill.dart';
import 'widgets/home_prayer_hero_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _uiTicker;
  PrayerPhase? _selectedPhase;
  double _syncTurns = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uiTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future<void>.microtask(_refreshData);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _syncTurns += 1.0);
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(activitiesProvider);
  }

  PrayerTime _currentPrayerFor(
    List<PrayerTime> prayers,
    PrayerPhase currentPhase,
  ) {
    for (final prayer in prayers) {
      if (prayer.phase == currentPhase) return prayer;
    }
    return prayers.first;
  }

  PrayerTime _nextPrayerFor(
    PrayerSchedule schedule,
    PrayerPhase currentPhase,
  ) {
    final idx = schedule.today.indexWhere((p) => p.phase == currentPhase);
    if (idx >= 0 && idx < schedule.today.length - 1) {
      return schedule.today[idx + 1];
    }
    return schedule.tomorrowFajr;
  }

  void _showAddActivitySheet({
    PrayerPhase? initialPhase,
    bool isIndependent = false,
    BuildContext? sourceContext,
    Color? sourceColor,
  }) {
    AddActivitySheet.open(
      context,
      initialPhase: isIndependent ? null : initialPhase,
      isIndependentInitial: isIndependent,
      sourceContext: sourceContext,
      sourceColor: sourceColor ?? Theme.of(context).scaffoldBackgroundColor,
      onSave: (activity) async {
        await ref.read(activitiesProvider.notifier).addActivity(activity);
        lightSuccessHaptic();
        if (mounted) {
          appSnack(context, 'أُضِيف النشاط — ${MotivationQuotes.randomLine()}');
        }
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(prayerScheduleProvider);
    final activities =
        ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
    final dayState = ref.watch(dayStateProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final activePhase = _selectedPhase ?? dayState.currentPrayerPhase;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        floatingActionButton: Builder(
          builder: (fabCtx) => FloatingActionButton.extended(
            heroTag: 'home_fab',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddActivitySheet(
                initialPhase: activePhase,
                sourceContext: fabCtx,
                sourceColor: theme.colorScheme.primaryContainer,
              );
            },
            label: const Text('إضافة نشاط'),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        body: scheduleAsync.when(
          skipLoadingOnReload: true,
          loading: () {
            if (scheduleAsync.hasValue) {
              return _buildBody(
                schedule: scheduleAsync.value!,
                activities: activities,
                dayState: dayState,
                selectedDate: selectedDate,
                todayStr: todayStr,
                nowStr: nowStr,
                activePhase: activePhase,
                theme: theme,
                isDark: isDark,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, _) => AppErrorView(
            error: error,
            onRetry: () => ref.invalidate(prayerScheduleProvider),
          ),
          data: (schedule) => _buildBody(
            schedule: schedule,
            activities: activities,
            dayState: dayState,
            selectedDate: selectedDate,
            todayStr: todayStr,
            nowStr: nowStr,
            activePhase: activePhase,
            theme: theme,
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required PrayerSchedule schedule,
    required List<ActivityItem> activities,
    required DayState dayState,
    required DateTime selectedDate,
    required String todayStr,
    required String nowStr,
    required PrayerPhase activePhase,
    required ThemeData theme,
    required bool isDark,
  }) {
    final prayers = schedule.today;
    if (prayers.isEmpty) {
      return const Center(child: Text('لا تتوفر بيانات للصلاة اليوم.'));
    }

    final currentPrayer =
        _currentPrayerFor(prayers, dayState.currentPrayerPhase);
    final nextPrayer = _nextPrayerFor(schedule, dayState.currentPrayerPhase);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: 90,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          actions: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: todayStr != nowStr
                  ? Padding(
                      key: const ValueKey('today_btn'),
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: _HomeHeaderPillButton(
                        icon: Icons.today_rounded,
                        tooltip: 'العودة لليوم',
                        color: theme.colorScheme.primary,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(selectedDateProvider.notifier).state =
                              DateTime.now();
                        },
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no_today_btn')),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: _HomeHeaderPillButton(
                icon: Icons.insights_rounded,
                tooltip: 'الإحصائيات',
                color: const Color(0xFF007AFF),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const StatsScreen(),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Tooltip(
                message: 'تحديث',
                child: Material(
                  color: isDark
                      ? const Color(0xFF152036)
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _refreshData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AnimatedRotation(
                        turns: _syncTurns,
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.sync_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(
              start: 20,
              bottom: 14,
              end: 120,
            ),
            centerTitle: false,
            title: GestureDetector(
              onTap: () {
                ref.read(selectedDateProvider.notifier).state = DateTime.now();
              },
              child: Text(
                'الرباط',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.6),
            child: Container(
              height: 0.6,
              color: theme.colorScheme.onSurface
                  .withValues(alpha: isDark ? 0.08 : 0.06),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth =
                  constraints.maxWidth > 650 ? 650.0 : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: maxContentWidth,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeDatePill(
                          selectedDate: selectedDate,
                          onPreviousDay: () {
                            ref.read(selectedDateProvider.notifier).state =
                                selectedDate.subtract(const Duration(days: 1));
                          },
                          onNextDay: () {
                            ref.read(selectedDateProvider.notifier).state =
                                selectedDate.add(const Duration(days: 1));
                          },
                          onPickDate: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              ref.read(selectedDateProvider.notifier).state =
                                  date;
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        HomePrayerHeroCard(
                          schedule: schedule,
                          currentPrayer: currentPrayer,
                          nextPrayer: nextPrayer,
                          currentPhase: dayState.currentPrayerPhase,
                          selectedPhase: activePhase,
                          activities: activities,
                          selectedDate: selectedDate,
                          todayStr: todayStr,
                          onSelectPhase: (phase) {
                            setState(() => _selectedPhase = phase);
                          },
                        ),
                        const SizedBox(height: 18),
                        HomePhaseActivitiesSection(
                          ref: ref,
                          activities: activities,
                          selectedDate: selectedDate,
                          todayStr: todayStr,
                          selectedPhase: activePhase,
                          onAddForPhase: (phase) =>
                              _showAddActivitySheet(initialPhase: phase),
                        ),
                        HomeIndependentActivitiesSection(
                          ref: ref,
                          activities: activities,
                          selectedDate: selectedDate,
                          todayStr: todayStr,
                          onAddIndependent: () =>
                              _showAddActivitySheet(isIndependent: true),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HomeHeaderPillButton extends StatelessWidget {
  const _HomeHeaderPillButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}
