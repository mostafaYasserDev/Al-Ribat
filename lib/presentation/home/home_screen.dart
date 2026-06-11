import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'package:flutter_slidable/flutter_slidable.dart';

import '../../application/providers.dart';
import '../../core/activity_schedule.dart';
import '../../core/constants/prayer_phase.dart';
import '../../core/ui_confirm.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/day_state.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/prayer_time.dart';
import '../../services/motivation_quotes.dart';
import '../projects/projects_screen.dart';
import '../widgets/add_activity_sheet.dart';
import '../widgets/reflection_card.dart';
import 'widgets/home_day_details_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  Timer? _uiTicker;

  PrayerTime _currentPrayerFor(List<PrayerTime> prayers, PrayerPhase currentPhase) {
    for (final prayer in prayers) {
      if (prayer.phase == currentPhase) return prayer;
    }
    return prayers.first;
  }

  List<ActivityItem> _activitiesForPhase(
    List<ActivityItem> activities,
    PrayerPhase phase,
    DateTime selectedDate,
  ) =>
      activitiesForPhase(activities, phase, selectedDate);

  List<ActivityItem> _independentActivities(
    List<ActivityItem> activities,
    DateTime selectedDate,
  ) =>
      independentActivities(activities, selectedDate);

  String _dailyMotivation() {
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return MotivationQuotes.pickFor(key);
  }

  Future<void> _refreshData() async {
    ref.invalidate(prayerScheduleProvider);
    await ref.read(activitiesProvider.notifier).build();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _uiTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    Future<void>.microtask(() async {
      await _refreshData();
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

  void _openActivitySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AddActivitySheet(
        onSave: (activity) async {
          await ref.read(activitiesProvider.notifier).addActivity(activity);
          lightSuccessHaptic();
          if (context.mounted) {
            appSnack(context, 'أُضِيف النشاط — ${MotivationQuotes.randomLine()}');
          }
          return true;
        },
      ),
    );
  }

  Future<void> _showAddProgressDialog(ActivityItem activity, String date) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة إنجاز: ${activity.title}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'أدخل المقدار (مثال: 5)',
            suffixText: activity.goalUnit,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              if (val > 0) {
                ref.read(activitiesProvider.notifier).addProgress(activity, date, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  String _formatProgress(double p) {
    return p == p.toInt() ? p.toInt().toString() : p.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(prayerScheduleProvider);
    final activities = ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
    final dayState = ref.watch(dayStateProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            ref.read(selectedDateProvider.notifier).state = DateTime.now();
          },
          child: const Text('الرباط'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_special_outlined),
            tooltip: 'المشاريع والمجموعات',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectsScreen()));
            },
          ),
          if (todayStr != nowStr)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: 'العودة لليوم',
              onPressed: () {
                ref.read(selectedDateProvider.notifier).state = DateTime.now();
              },
            ),
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              _refreshData();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _openActivitySheet(context);
        },
        label: const Text('إضافة نشاط'),
        icon: const Icon(Icons.add),
      ),
      body: scheduleAsync.when(
        skipLoadingOnReload: true,
        loading: () {
          if (scheduleAsync.hasValue) {
             return _buildContent(context, ref, scheduleAsync.value!, activities, dayState, selectedDate, todayStr);
          }
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'تعذر تحميل أوقات الصلاة.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (schedule) => _buildContent(context, ref, schedule, activities, dayState, selectedDate, todayStr),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, 
    WidgetRef ref, 
    PrayerSchedule schedule, 
    List<ActivityItem> activities, 
    DayState dayState, 
    DateTime selectedDate, 
    String todayStr,
  ) {
    final prayers = schedule.today;
    if (prayers.isEmpty) {
      return const Center(child: Text('لا تتوفر بيانات للصلاة اليوم.'));
    }
    final settings = ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final suggestion = _buildSuggestion(prayers, activities, dayState.currentPrayerPhase, selectedDate);
    final currentPrayer = _currentPrayerFor(prayers, dayState.currentPrayerPhase);
    final currentActivities = _activitiesForPhase(activities, dayState.currentPrayerPhase, selectedDate);
    
    final light = Theme.of(context).brightness == Brightness.light;
    final bgColors = light
        ? dayState.currentPrayerPhase.lightGradient
        : const [Color(0xFF071320), Color(0xFF0A1B2A), Color(0xFF122437)];
        
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth = constraints.maxWidth > 700 ? 700.0 : constraints.maxWidth;
          return Center(
            child: SizedBox(
              width: maxContentWidth,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          ref.read(selectedDateProvider.notifier).state = selectedDate.subtract(const Duration(days: 1));
                        },
                      ),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            ref.read(selectedDateProvider.notifier).state = date;
                          }
                        },
                        child: Text(
                          DateFormat('EEEE · d MMMM yyyy', 'ar').format(selectedDate),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFF142018)
                                    : null,
                                shadows: Theme.of(context).brightness == Brightness.dark
                                    ? const [Shadow(blurRadius: 10, color: Colors.black26)]
                                    : null,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          ref.read(selectedDateProvider.notifier).state = selectedDate.add(const Duration(days: 1));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: light ? const Color(0xFFEAF4ED) : const Color(0xFF123226),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: light ? const Color(0xFFC8E0CC) : const Color(0xFF2D5A49),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, color: light ? const Color(0xFF2F6D4B) : const Color(0xFF9ED9B9)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dailyMotivation(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: light ? const Color(0xFF1E4F35) : const Color(0xFFD7F3E5),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: light
                            ? const [Color(0xFFF6F8FF), Color(0xFFEAF1FF)]
                            : const [Color(0xFF0C2036), Color(0xFF15304A)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      border: Border.all(
                        color: light ? const Color(0xFFD2DBEE) : const Color(0xFF2B4D70),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: light ? 0.08 : 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'أولوياتك الحالية: ${currentPrayer.phase.arabicName}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Text(DateFormat.jm('ar').format(currentPrayer.time)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            suggestion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Text('المهام والأنشطة الآن', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 6),
                          if (currentActivities.isEmpty)
                            Text(
                              MotivationQuotes.randomEmptyLine(),
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          else
                            ...currentActivities.take(4).map(
                                  (act) {
                                    final isDone = act.isDoneOn(todayStr);
                                    final isSkipped = act.isSkippedOn(todayStr);
                                    return Slidable(
                                      key: ValueKey(act.id),
                                      startActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed: (_) {
                                              HapticFeedback.selectionClick();
                                              final wasDone = act.isDoneOn(todayStr);
                                              ref.read(activitiesProvider.notifier).toggleDone(act, todayStr);
                                              if (!wasDone && context.mounted) {
                                                showCelebration(context, MotivationQuotes.randomLine());
                                              }
                                            },
                                            backgroundColor: isDone ? Colors.grey : Colors.green,
                                            foregroundColor: Colors.white,
                                            icon: isDone ? Icons.undo : Icons.done,
                                            label: isDone ? 'تراجع' : 'إنجاز',
                                          ),
                                        ],
                                      ),
                                      endActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        children: [
                                          if (!isDone)
                                            SlidableAction(
                                              onPressed: (_) {
                                                HapticFeedback.selectionClick();
                                                ref.read(activitiesProvider.notifier).toggleSkip(act, todayStr);
                                              },
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              icon: isSkipped ? Icons.undo : Icons.skip_next,
                                              label: isSkipped ? 'تراجع عن التخطي' : 'تخطي',
                                            ),
                                          SlidableAction(
                                            onPressed: (_) async {
                                              final option = await showActivityDeleteOptions(context, act.title);
                                              if (option == null || !context.mounted) return;
                                              switch (option) {
                                                case ActivityDeleteOption.skipToday:
                                                  ref.read(activitiesProvider.notifier).toggleSkip(act, todayStr);
                                                  break;
                                                case ActivityDeleteOption.endFuture:
                                                  final previousDate = DateTime.parse(todayStr).subtract(const Duration(days: 1));
                                                  final prevStr = "${previousDate.year.toString().padLeft(4, '0')}-${previousDate.month.toString().padLeft(2, '0')}-${previousDate.day.toString().padLeft(2, '0')}";
                                                  await ref.read(activitiesProvider.notifier).updateActivity(act.copyWith(endDate: prevStr));
                                                  break;
                                                case ActivityDeleteOption.deleteCompletely:
                                                  await ref.read(activitiesProvider.notifier).deleteActivity(act.id);
                                                  break;
                                              }
                                              if (context.mounted) appSnack(context, 'تم تنفيذ الإجراء بنجاح.');
                                            },
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            icon: Icons.delete,
                                            label: 'حذف',
                                          ),
                                          SlidableAction(
                                            onPressed: (_) async {
                                              final updated = await showModalBottomSheet<ActivityItem>(
                                                context: context,
                                                isScrollControlled: true,
                                                showDragHandle: true,
                                                builder: (ctx) => AddActivitySheet(
                                                  initialActivity: act,
                                                  onSave: (edited) async {
                                                    Navigator.of(ctx).pop(edited);
                                                    return true;
                                                  },
                                                ),
                                              );
                                              if (updated != null) {
                                                HapticFeedback.lightImpact();
                                                await ref.read(activitiesProvider.notifier).updateActivity(updated);
                                                if (context.mounted) appSnack(context, 'تم تعديل النشاط.');
                                              }
                                            },
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            icon: Icons.edit,
                                            label: 'تعديل',
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          isDone ? Icons.check_circle : (isSkipped ? Icons.next_plan : Icons.circle_outlined),
                                          color: isDone ? Colors.green : (isSkipped ? Colors.orange : null),
                                        ),
                                        title: Text(
                                          act.title,
                                          style: TextStyle(
                                            decoration: isDone || isSkipped ? TextDecoration.lineThrough : null,
                                            color: isSkipped ? Colors.grey : null,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${act.reminderHour != null ? TimeOfDay(hour: act.reminderHour!, minute: act.reminderMinute!).format(context) : ''}'
                                          '${act.description != null ? ' · ${act.description}' : ''}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: act.isMeasurable
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${_formatProgress(act.getProgressOn(todayStr))} / ${_formatProgress(act.targetGoal ?? 1)} ${act.goalUnit ?? ""}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle_outline),
                                                    onPressed: () => _showAddProgressDialog(act, todayStr),
                                                  ),
                                                ],
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                          if (currentActivities.length > 4)
                            Text(
                              'هناك ${currentActivities.length - 4} نشاط إضافي في التفاصيل.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            
                          if (activities.length == 1) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'تلميح: اسحب النشاط لليمين لإنجازه، ولليسار لتخطيه أو حذفه.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  // Independent Activities Block
                  Builder(
                    builder: (context) {
                      final indepActs = _independentActivities(activities, selectedDate);
                      if (indepActs.isEmpty) return const SizedBox();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          Text('الأنشطة الحرة', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).cardColor,
                              border: Border.all(
                                color: light ? const Color(0xFFD2DBEE) : const Color(0xFF2B4D70),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: indepActs.take(3).length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final act = indepActs[index];
                                final isDone = act.isDoneOn(todayStr);
                                final isSkipped = act.isSkippedOn(todayStr);
                                return Slidable(
                                  key: ValueKey(act.id),
                                  startActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) {
                                          HapticFeedback.selectionClick();
                                          final wasDone = act.isDoneOn(todayStr);
                                          ref.read(activitiesProvider.notifier).toggleDone(act, todayStr);
                                          if (!wasDone && context.mounted) {
                                            showCelebration(context, MotivationQuotes.randomLine());
                                          }
                                        },
                                        backgroundColor: isDone ? Colors.grey : Colors.green,
                                        foregroundColor: Colors.white,
                                        icon: isDone ? Icons.undo : Icons.done,
                                        label: isDone ? 'تراجع' : 'إنجاز',
                                      ),
                                    ],
                                  ),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      if (!isDone)
                                        SlidableAction(
                                          onPressed: (_) {
                                            HapticFeedback.selectionClick();
                                            ref.read(activitiesProvider.notifier).toggleSkip(act, todayStr);
                                          },
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                          icon: isSkipped ? Icons.undo : Icons.skip_next,
                                          label: isSkipped ? 'تراجع عن التخطي' : 'تخطي',
                                        ),
                                      SlidableAction(
                                        onPressed: (_) async {
                                          final option = await showActivityDeleteOptions(context, act.title);
                                          if (option == null || !context.mounted) return;
                                          switch (option) {
                                            case ActivityDeleteOption.skipToday:
                                              ref.read(activitiesProvider.notifier).toggleSkip(act, todayStr);
                                              break;
                                            case ActivityDeleteOption.endFuture:
                                              final previousDate = DateTime.parse(todayStr).subtract(const Duration(days: 1));
                                              final prevStr = "${previousDate.year.toString().padLeft(4, '0')}-${previousDate.month.toString().padLeft(2, '0')}-${previousDate.day.toString().padLeft(2, '0')}";
                                              await ref.read(activitiesProvider.notifier).updateActivity(act.copyWith(endDate: prevStr));
                                              break;
                                            case ActivityDeleteOption.deleteCompletely:
                                              await ref.read(activitiesProvider.notifier).deleteActivity(act.id);
                                              break;
                                          }
                                          if (context.mounted) appSnack(context, 'تم تنفيذ الإجراء بنجاح.');
                                        },
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: 'حذف',
                                      ),
                                      SlidableAction(
                                        onPressed: (_) async {
                                          final updated = await showModalBottomSheet<ActivityItem>(
                                            context: context,
                                            isScrollControlled: true,
                                            showDragHandle: true,
                                            builder: (ctx) => AddActivitySheet(
                                              initialActivity: act,
                                              onSave: (edited) async {
                                                Navigator.of(ctx).pop(edited);
                                                return true;
                                              },
                                            ),
                                          );
                                          if (updated != null) {
                                            HapticFeedback.lightImpact();
                                            await ref.read(activitiesProvider.notifier).updateActivity(updated);
                                            if (context.mounted) appSnack(context, 'تم تعديل النشاط.');
                                          }
                                        },
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                        label: 'تعديل',
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      isDone ? Icons.check_circle : (isSkipped ? Icons.next_plan : Icons.circle_outlined),
                                      color: isDone ? Colors.green : (isSkipped ? Colors.orange : null),
                                    ),
                                    title: Text(
                                      act.title,
                                      style: TextStyle(
                                        decoration: isDone || isSkipped ? TextDecoration.lineThrough : null,
                                        color: isSkipped ? Colors.grey : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${act.projectName ?? 'نشاط حر'}'
                                      '${act.description != null ? ' · ${act.description}' : ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: act.isMeasurable
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '${_formatProgress(act.getProgressOn(todayStr))} / ${_formatProgress(act.targetGoal ?? 1)} ${act.goalUnit ?? ""}',
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle_outline),
                                                onPressed: () => _showAddProgressDialog(act, todayStr),
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => openDayDetailsSheet(
                            context: context,
                            schedule: schedule,
                            settings: settings,
                          ),
                          icon: const Icon(Icons.view_agenda_outlined),
                          label: const Text('عرض تفاصيل اليوم'),
                        ),
                      ),
                    ],
                  ),
                  if (dayState.currentPrayerPhase == PrayerPhase.isha || todayStr != DateFormat('yyyy-MM-dd').format(DateTime.now()))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ReflectionCard(
                        streakCount: max(dayState.streakCount, 1),
                        onSave: (value, mood) async {
                          final selectedDate = ref.read(selectedDateProvider);
                          final at = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            DateTime.now().hour,
                            DateTime.now().minute,
                          );
                          await ref.read(reflectionsProvider.notifier).add(value, mood: mood, createdAt: at);
                          await updateStreakIfNeeded(ref);
                          if (context.mounted) {
                            lightSuccessHaptic();
                            appSnack(context, 'حُفِظ التأمل في السجل.');
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildSuggestion(
    List<PrayerTime> prayers,
    List<ActivityItem> activities,
    PrayerPhase currentPhase,
    DateTime selectedDate,
  ) {
    final todayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final now = DateTime.now();
    // Only show countdown if the selected date is today
    final isToday = todayStr == DateFormat('yyyy-MM-dd').format(now);
    
    final inCurrentPhase = _activitiesForPhase(activities, currentPhase, selectedDate);
    final completedRate = inCurrentPhase.isEmpty
        ? 0
        : (inCurrentPhase.where((e) => e.isDoneOn(todayStr)).length * 100 ~/ inCurrentPhase.length);
        
    if (isToday) {
      for (var i = 0; i < prayers.length; i++) {
        final current = prayers[i];
        final next = i < prayers.length - 1 ? prayers[i + 1] : null;
        final curTime = current.time;
        if (next != null) {
          if (!now.isAfter(curTime) || !now.isBefore(next.time)) {
            continue;
          }
          final remaining = next.time.difference(now).inMinutes;
          if (remaining <= 30) {
            return 'تبقى $remaining دقيقة قبل ${next.phase.arabicName}.';
          }
        } else {
          if (!now.isAfter(curTime)) {
            continue;
          }
        }
        if (completedRate >= 70) {
          return 'أداؤك ممتاز في هذه المرحلة.';
        }
        final incomplete = inCurrentPhase.where((e) => !e.isDoneOn(todayStr)).length;
        return incomplete == 0
            ? 'مرحلة جديدة — ما الهدف التالي؟'
            : 'لديك $incomplete نشاط متبقي.';
      }
      return 'هدوء وتركيز بين الصلوات.';
    } else {
      if (completedRate >= 100) return 'لقد أنجزت كل الأنشطة هذه المرحلة.';
      final incomplete = inCurrentPhase.where((e) => !e.isDoneOn(todayStr)).length;
      return incomplete == 0 ? 'لا توجد أنشطة لهذه المرحلة.' : 'كان لديك $incomplete نشاط متبقي.';
    }
  }
}
