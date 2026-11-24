part of '../home_screen.dart';

mixin _HomeScreenStateMixin
    on ConsumerState<HomeScreen>, WidgetsBindingObserver {
  Timer? _uiTicker;
  PrayerPhase? _selectedPhase;

  Future<void> _refreshData() async {
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(activitiesProvider);
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

    return Scaffold(
      appBar: _buildHomeAppBar(context, ref, todayStr, nowStr, _refreshData),
      floatingActionButton: _buildHomeFab(context, () {
        HapticFeedback.lightImpact();
        _showAddActivitySheet(
          context,
          ref,
          initialPhase: activePhase,
        );
      }),
      body: scheduleAsync.when(
        skipLoadingOnReload: true,
        loading: () {
          if (scheduleAsync.hasValue) {
            return _buildContent(scheduleAsync.value!, activities, dayState,
                selectedDate, todayStr, activePhase);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, _) => _buildScheduleError(
          context,
          error,
          onRetry: () => ref.invalidate(prayerScheduleProvider),
        ),
        data: (schedule) => _buildContent(schedule, activities, dayState,
            selectedDate, todayStr, activePhase),
      ),
    );
  }

  Widget _buildContent(
    PrayerSchedule schedule,
    List<ActivityItem> activities,
    DayState dayState,
    DateTime selectedDate,
    String todayStr,
    PrayerPhase activePhase,
  ) {
    return _buildHomeContent(
      context: context,
      ref: ref,
      schedule: schedule,
      activities: activities,
      dayState: dayState,
      selectedDate: selectedDate,
      todayStr: todayStr,
      selectedPhase: activePhase,
      onSelectPhase: (phase) {
        setState(() {
          _selectedPhase = phase;
        });
      },
      onAddForPhase: (phase) =>
          _showAddActivitySheet(context, ref, initialPhase: phase),
      onAddIndependent: () =>
          _showAddActivitySheet(context, ref, isIndependent: true),
    );
  }
}
