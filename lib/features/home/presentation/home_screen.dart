import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../application/providers.dart';
import '../../../core/constants/prayer_phase.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../../../core/widgets/arabic_date_popover.dart';
import '../../../domain/entities/activity_item.dart';
import '../../../domain/entities/day_state.dart';
import '../../../domain/entities/prayer_schedule.dart';
import '../../../domain/entities/prayer_time.dart';
import '../../../presentation/stats/stats_screen.dart';
import '../../ai_assistant/presentation/ai_chat_screen.dart';
import '../../ai_assistant/presentation/widgets/ai_proactive_banner.dart';
import '../../../presentation/widgets/add_activity_sheet.dart';
import '../../../services/motivation_quotes.dart';
import 'widgets/home_activities_sections.dart';
import 'widgets/home_date_pill.dart';
import 'widgets/home_prayer_hero_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _uiTicker;
  PrayerPhase? _selectedPhase;
  double _syncTurns = 0.0;

  /// Opens the Add Activity sheet from the center dock orb in [AppShell].
  void openAddActivityFromShell({
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 27,
  }) {
    if (!mounted) return;
    final dayState = ref.read(dayStateProvider);
    final activePhase = _selectedPhase ?? dayState.currentPrayerPhase;
    _showAddActivitySheet(
      initialPhase: activePhase,
      sourceContext: sourceContext,
      sourceColor: sourceColor,
      sourceRadius: sourceRadius,
    );
  }

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
    final now = DateTime.now();
    if (schedule.today.isNotEmpty &&
        currentPhase == PrayerPhase.isha &&
        now.isBefore(schedule.today.first.time)) {
      return schedule.today.first;
    }
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
    double sourceRadius = 18,
  }) {
    AddActivitySheet.open(
      context,
      initialPhase: isIndependent ? null : initialPhase,
      isIndependentInitial: isIndependent,
      sourceContext: sourceContext,
      sourceColor: sourceColor ?? Theme.of(context).scaffoldBackgroundColor,
      sourceRadius: sourceRadius,
      onSave: (activity) async {
        await ref.read(activitiesProvider.notifier).addActivity(activity);
        lightSuccessHaptic();
        if (mounted) {
          final sel = ref.read(selectedDateProvider);
          final now = DateTime.now();
          final isToday = sel.year == now.year &&
              sel.month == now.month &&
              sel.day == now.day;
          final prefix = isToday
              ? 'أُضِيف النشاط'
              : 'أُضِيف النشاط ليوم ${DateFormat('d MMMM', 'ar').format(sel)}';
          appSnack(context, '$prefix — ${MotivationQuotes.randomLine()}');
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
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Builder(
                builder: (aiBtnCtx) => _HomeHeaderPillButton(
                  icon: Icons.auto_awesome_rounded,
                  tooltip: 'المساعد الذكي (RibatAI)',
                  color: const Color(0xFF5856D6),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AiChatScreen.open(
                      context,
                      sourceContext: aiBtnCtx,
                      sourceColor: isDark
                          ? const Color(0xFF1D1B38)
                          : const Color(0xFF5856D6).withValues(alpha: 0.14),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Builder(
                builder: (statsBtnCtx) => _HomeHeaderPillButton(
                  icon: Icons.insights_rounded,
                  tooltip: 'الإحصائيات',
                  color: const Color(0xFF007AFF),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    StatsScreen.open(
                      context,
                      sourceContext: statsBtnCtx,
                      sourceColor: isDark
                          ? const Color(0xFF152036)
                          : const Color(0xFF007AFF).withValues(alpha: 0.14),
                    );
                  },
                ),
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
                          onReturnToToday: () {
                            ref.read(selectedDateProvider.notifier).state =
                                DateTime.now();
                          },
                          onPickDate: (anchorCtx) {
                            showArabicDatePopover(
                              anchorCtx,
                              initialDate: selectedDate,
                              onSelected: (date) {
                                ref.read(selectedDateProvider.notifier).state =
                                    date;
                              },
                            );
                          },
                        ),
                        const AiProactiveBanner(),
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
