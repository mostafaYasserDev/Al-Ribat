import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../application/providers.dart';
import '../../core/constants/prayer_phase.dart';
import '../../core/habit_anchor_phase.dart';
import '../../core/prayer_slot_conflict.dart';
import '../../core/task_time_rules.dart';
import '../../core/ui_confirm.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/habit_item.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/entities/task_item.dart';
import '../../domain/entities/prayer_time.dart';
import '../../services/motivation_quotes.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/prayer_card.dart';
import '../widgets/reflection_card.dart';

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

  List<HabitItem> _habitsForPhase(
    PrayerSchedule schedule,
    List<HabitItem> habits,
    PrayerPhase phase,
  ) {
    final weekday = DateTime.now().weekday;
    return habits.where((h) {
      if (!habitIsActiveOnWeekday(h, weekday)) return false;
      return anchorPrayerPhaseForReminder(schedule, h) == phase;
    }).toList();
  }

  String _betweenAdhanSentence(PrayerTime current, PrayerSchedule schedule) {
    final idx = schedule.today.indexWhere((p) => p.phase == current.phase);
    final next = (idx >= 0 && idx < schedule.today.length - 1)
        ? schedule.today[idx + 1]
        : schedule.tomorrowFajr;
    final d = next.time.difference(current.time);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final duration = h > 0 ? '$h ساعة${m > 0 ? ' و $m دقيقة' : ''}' : '$m دقيقة';
    return 'بين أذان ${current.phase.arabicName} و${next.phase.arabicName}: $duration';
  }

  String _dailyMotivation() {
    final key = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return MotivationQuotes.pickFor(key);
  }

  Future<void> _refreshData() async {
    ref.invalidate(prayerScheduleProvider);
    await ref.read(tasksProvider.notifier).load();
    await ref.read(habitsProvider.notifier).load();
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

  void _showAddMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_task),
              title: const Text('مهمة جديدة'),
              onTap: () {
                Navigator.pop(context);
                _openTaskSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat),
              title: const Text('عادة جديدة'),
              onTap: () {
                Navigator.pop(context);
                _openHabitSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openDayDetailsSheet({
    required PrayerSchedule schedule,
    required List<TaskItem> tasks,
    required List<HabitItem> habits,
    required AppSettings settings,
    required PrayerPhase currentPhase,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.84,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                children: [
                Text(
                  'تفاصيل اليوم حسب الصلوات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...schedule.today.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PrayerCard(
                      prayer: p,
                      prayerSchedule: schedule,
                      prayerSlotMinutes: settings.prayerSlotDurationMinutes,
                      footerNote: _betweenAdhanSentence(p, schedule),
                      tasks: tasks.where((t) => t.linkedPrayer == p.phase).toList(),
                      habits: _habitsForPhase(schedule, habits, p.phase),
                      onToggleTask: (task) {
                        HapticFeedback.selectionClick();
                        ref.read(tasksProvider.notifier).toggleTask(task);
                      },
                      onDeleteTask: (task) async {
                        mediumHaptic();
                        await ref.read(tasksProvider.notifier).deleteTask(task.id);
                        if (context.mounted) {
                          appSnack(context, 'حُذفت المهمة.');
                        }
                      },
                      onEditTask: (updated) => ref.read(tasksProvider.notifier).editTask(updated),
                      onReorderWithinPhase: (movedTask, newIndex) => ref
                          .read(tasksProvider.notifier)
                          .reorder(movedTask, newIndex, tasks),
                      onMarkHabitDone: (h) async {
                        await ref.read(habitsProvider.notifier).markDoneToday(h);
                        lightSuccessHaptic();
                        if (context.mounted) {
                          appSnack(context, 'أحسنت! ${MotivationQuotes.randomLine()}');
                        }
                      },
                      onClearHabitDone: (h) async {
                        await ref.read(habitsProvider.notifier).clearDoneToday(h);
                        HapticFeedback.selectionClick();
                        if (context.mounted) {
                          appSnack(context, 'أُلغي إتمام العادة لهذا اليوم.');
                        }
                      },
                      onDeleteHabit: (h) async {
                        final ok = await confirmDestructiveAction(
                          context,
                          title: 'حذف العادة؟',
                          message: 'لن يمكن استرجاع «${h.title}».',
                        );
                        if (!ok || !context.mounted) return;
                        mediumHaptic();
                        await ref.read(habitsProvider.notifier).deleteHabit(h.id);
                        if (context.mounted) {
                          appSnack(context, 'تم حذف العادة.');
                        }
                      },
                      onEditHabit: (habit) async {
                        await ref.read(habitsProvider.notifier).updateHabit(habit);
                        if (context.mounted) appSnack(context, 'تم تعديل العادة.');
                      },
                    ),
                  ),
                ),
                  if (currentPhase == PrayerPhase.isha)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ReflectionCard(
                        streakCount: max(ref.watch(dayStateProvider).streakCount, 1),
                        onSave: (value) async {
                          await ref.read(reflectionsProvider.notifier).add(value);
                          await updateStreakIfNeeded(ref);
                          if (context.mounted) {
                            lightSuccessHaptic();
                            appSnack(context, 'حُفظ التأمل في السجل.');
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(prayerScheduleProvider);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <TaskItem>[];
    final habits = ref.watch(habitsProvider).valueOrNull ?? const <HabitItem>[];
    final dayState = ref.watch(dayStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرباط'),
        actions: [
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
          _showAddMenu();
        },
        label: const Text('إضافة'),
        icon: const Icon(Icons.add),
      ),
      body: scheduleAsync.when(
        data: (schedule) {
          final prayers = schedule.today;
          if (prayers.isEmpty) {
            return const Center(child: Text('لا تتوفر بيانات للصلاة اليوم.'));
          }
          final settings = ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
          final suggestion = _buildSuggestion(prayers, tasks, dayState.currentPrayerPhase);
          final currentPrayer = _currentPrayerFor(prayers, dayState.currentPrayerPhase);
          final currentTasks =
              tasks.where((t) => t.linkedPrayer == dayState.currentPrayerPhase).toList();
          final currentHabits = _habitsForPhase(schedule, habits, dayState.currentPrayerPhase);
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
                Text(
                  DateFormat('EEEE · d MMMM', 'ar').format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF142018)
                            : null,
                        shadows: Theme.of(context).brightness == Brightness.dark
                            ? const [Shadow(blurRadius: 10, color: Colors.black26)]
                            : null,
                      ),
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
                        Text(
                          'المهام الآن (${currentTasks.where((e) => !e.isCompleted).length} غير مكتملة)',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        if (currentTasks.isEmpty)
                          Text(
                            'لا توجد مهام لهذه الفترة.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          ...currentTasks.take(4).map(
                                (task) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Checkbox(
                                    value: task.isCompleted,
                                    onChanged: (_) {
                                      HapticFeedback.selectionClick();
                                      ref.read(tasksProvider.notifier).toggleTask(task);
                                    },
                                  ),
                                  title: Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      decoration:
                                          task.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    tooltip: 'خيارات المهمة',
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        final ok = await confirmDestructiveAction(
                                          context,
                                          title: 'حذف المهمة؟',
                                          message: 'لن يمكن استرجاع «${task.title}».',
                                        );
                                        if (!ok || !context.mounted) return;
                                        await ref.read(tasksProvider.notifier).deleteTask(task.id);
                                        if (context.mounted) appSnack(context, 'حُذفت المهمة.');
                                        return;
                                      }
                                      final updated = await showDialog<TaskItem>(
                                        context: context,
                                        builder: (context) => _HomeTaskEditDialog(
                                          task: task,
                                          schedule: schedule,
                                          slotMinutes: settings.prayerSlotDurationMinutes,
                                        ),
                                      );
                                      if (updated != null) {
                                        await ref.read(tasksProvider.notifier).editTask(updated);
                                        if (context.mounted) appSnack(context, 'تم تعديل المهمة.');
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('تعديل')),
                                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                                    ],
                                  ),
                                ),
                              ),
                        if (currentTasks.length > 4)
                          Text(
                            'هناك ${currentTasks.length - 4} مهام إضافية في التفاصيل.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        const SizedBox(height: 8),
                        Text('العادات الآن', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        if (currentHabits.isEmpty)
                          Text(
                            'لا توجد عادات لهذه الفترة.',
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          ...currentHabits.take(4).map(
                                (habit) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    habit.isDoneToday ? Icons.check_circle : Icons.circle_outlined,
                                    color: habit.isDoneToday ? Colors.green : null,
                                  ),
                                  title: Text(
                                    habit.title,
                                    style: TextStyle(
                                      decoration:
                                          habit.isDoneToday ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${TimeOfDay(hour: habit.reminderHour, minute: habit.reminderMinute).format(context)}'
                                    '${habit.description == null ? '' : ' · ${habit.description}'}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: 'تعديل',
                                        onPressed: () async {
                                          final updated = await showModalBottomSheet<HabitItem>(
                                            context: context,
                                            isScrollControlled: true,
                                            showDragHandle: true,
                                            builder: (ctx) => AddHabitSheet(
                                              initialHabit: habit,
                                              onSave: (h) async {
                                                Navigator.of(ctx).pop(h);
                                                return true;
                                              },
                                            ),
                                          );
                                          if (updated != null) {
                                            await ref.read(habitsProvider.notifier).updateHabit(updated);
                                            if (context.mounted) appSnack(context, 'تم تعديل العادة.');
                                          }
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                      if (!habit.isDoneToday)
                                        IconButton(
                                          tooltip: 'تم اليوم',
                                          onPressed: () =>
                                              ref.read(habitsProvider.notifier).markDoneToday(habit),
                                          icon: const Icon(Icons.done_outline),
                                        )
                                      else
                                        IconButton(
                                          tooltip: 'إلغاء الإتمام',
                                          onPressed: () => ref
                                              .read(habitsProvider.notifier)
                                              .clearDoneToday(habit),
                                          icon: const Icon(Icons.undo),
                                        ),
                                      IconButton(
                                        tooltip: 'حذف',
                                        onPressed: () async {
                                          final ok = await confirmDestructiveAction(
                                            context,
                                            title: 'حذف العادة؟',
                                            message: 'لن يمكن استرجاع «${habit.title}».',
                                          );
                                          if (!ok || !context.mounted) return;
                                          await ref.read(habitsProvider.notifier).deleteHabit(habit.id);
                                          if (context.mounted) appSnack(context, 'تم حذف العادة.');
                                        },
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openDayDetailsSheet(
                          schedule: schedule,
                          tasks: tasks,
                          habits: habits,
                          settings: settings,
                          currentPhase: dayState.currentPrayerPhase,
                        ),
                        icon: const Icon(Icons.view_agenda_outlined),
                        label: const Text('عرض تفاصيل اليوم'),
                      ),
                    ),
                  ],
                ),
                if (dayState.currentPrayerPhase == PrayerPhase.isha)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ReflectionCard(
                      streakCount: max(dayState.streakCount, 1),
                      onSave: (value) async {
                        await ref.read(reflectionsProvider.notifier).add(value);
                        await updateStreakIfNeeded(ref);
                        if (context.mounted) {
                          lightSuccessHaptic();
                          appSnack(context, 'حُفظ التأمل في السجل.');
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'تعذر تحميل أوقات الصلاة.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _openTaskSheet(BuildContext context) {
    final schedule = ref.read(prayerScheduleProvider).valueOrNull;
    final settings = ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTaskSheet(
        schedule: schedule,
        prayerSlotMinutes: settings.prayerSlotDurationMinutes,
        onSave: (title, description, prayer, type, startM, endM, reminderM) async {
          if ((reminderM != null) && !settings.notificationsEnabled) {
            if (context.mounted) {
              appSnackTop(context, 'الإشعارات العامة متوقفة. فعّلها من الإعدادات ليعمل التذكير.');
            }
            return false;
          }
          var linkedPrayer = prayer;
          var linkedType = type;
          if (schedule != null) {
            final basisMinute = startM ?? reminderM;
            if (basisMinute != null) {
              final inferred = inferPrayerTypeForMinute(
                schedule: schedule,
                minuteOfDay: basisMinute,
              );
              linkedPrayer = inferred.prayer;
              linkedType = inferred.type;
            }
          }
          if (schedule != null && startM != null && endM != null) {
            final day = DateTime.now();
            final start = DateTime(day.year, day.month, day.day).add(Duration(minutes: startM));
            final end = DateTime(day.year, day.month, day.day).add(Duration(minutes: endM));
            if (!end.isAfter(start)) {
              if (context.mounted) {
                appSnackTop(context, 'وقت الانتهاء يجب أن يكون بعد البدء.');
              }
              return false;
            }
            if (prayerSlotOverlaps(
              schedule: schedule,
              slotMinutes: settings.prayerSlotDurationMinutes,
              rangeStart: start,
              rangeEnd: end,
            )) {
              final suggested = nextAllowedMoment(
                schedule: schedule,
                slotMinutes: settings.prayerSlotDurationMinutes,
                at: start,
              );
              if (context.mounted) {
                appSnackTop(
                  context,
                  'لا يمكن الجدولة داخل وقت الصلاة. جرّب بعد ${DateFormat.jm('ar').format(suggested)}.',
                );
              }
              return false;
            }
          }
          if (schedule != null && reminderM != null) {
            final day = DateTime.now();
            final at = DateTime(day.year, day.month, day.day).add(Duration(minutes: reminderM));
            if (!at.isAfter(DateTime.now())) {
              if (context.mounted) {
                appSnackTop(context, 'اختر وقت تذكير قادم وليس وقتًا ماضيًا.');
              }
              return false;
            }
            if (prayerSlotOverlaps(
              schedule: schedule,
              slotMinutes: settings.prayerSlotDurationMinutes,
              rangeStart: at,
              rangeEnd: at.add(const Duration(minutes: 1)),
            )) {
              final suggested = nextAllowedMoment(
                schedule: schedule,
                slotMinutes: settings.prayerSlotDurationMinutes,
                at: at,
              );
              if (context.mounted) {
                appSnackTop(
                  context,
                  'وقت التذكير داخل وقت الصلاة. اختر بعد ${DateFormat.jm('ar').format(suggested)}.',
                );
              }
              return false;
            }
          }
          final existing = ref.read(tasksProvider).valueOrNull ?? const <TaskItem>[];
          final task = TaskItem(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: title,
            description: description.isEmpty ? null : description,
            linkedPrayer: linkedPrayer,
            type: linkedType,
            isCompleted: false,
            orderIndex: existing.length,
            createdAt: DateTime.now(),
            startMinutesFromMidnight: startM,
            endMinutesFromMidnight: endM,
            reminderMinutesFromMidnight: reminderM,
          );
          await ref.read(tasksProvider.notifier).addTask(task);
          lightSuccessHaptic();
          if (context.mounted) appSnack(context, 'أُضيفت المهمة.');
          return true;
        },
      ),
    );
  }

  void _openHabitSheet(BuildContext context) {
    final schedule = ref.read(prayerScheduleProvider).valueOrNull;
    final settings = ref.read(settingsProvider).valueOrNull ?? AppSettings.defaults;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddHabitSheet(
        onSave: (habit) async {
          if (habit.notificationsEnabled && !settings.notificationsEnabled) {
            if (context.mounted) {
              appSnackTop(context, 'الإشعارات العامة متوقفة. فعّلها من الإعدادات ليعمل تذكير العادة.');
            }
            return false;
          }
          if (schedule != null && habit.notificationsEnabled) {
            if (habitReminderConflicts(
              schedule: schedule,
              slotMinutes: settings.prayerSlotDurationMinutes,
              hour: habit.reminderHour,
              minute: habit.reminderMinute,
            )) {
              final now = DateTime.now();
              final suggested = nextAllowedMoment(
                schedule: schedule,
                slotMinutes: settings.prayerSlotDurationMinutes,
                at: DateTime(now.year, now.month, now.day, habit.reminderHour, habit.reminderMinute),
              );
              if (context.mounted) {
                appSnackTop(
                  context,
                  'وقت التذكير يقع داخل وقت الصلاة. جرّب ${DateFormat.jm('ar').format(suggested)} أو بعده.',
                );
              }
              return false;
            }
          }
          await ref.read(habitsProvider.notifier).addHabit(habit);
          lightSuccessHaptic();
          if (context.mounted) {
            appSnack(context, 'أُضيفت العادة — ${MotivationQuotes.randomLine()}');
          }
          return true;
        },
      ),
    );
  }

  String _buildSuggestion(
    List<PrayerTime> prayers,
    List<TaskItem> tasks,
    PrayerPhase currentPhase,
  ) {
    final now = DateTime.now();
    final inCurrentPhase = tasks.where((e) => e.linkedPrayer == currentPhase).toList();
    final completedRate = inCurrentPhase.isEmpty
        ? 0
        : (inCurrentPhase.where((e) => e.isCompleted).length * 100 ~/ inCurrentPhase.length);
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
      final incomplete = tasks.where((e) => !e.isCompleted).length;
      return incomplete == 0
          ? 'مرحلة جديدة — ما الهدف التالي؟'
          : 'لديك $incomplete مهام غير مكتملة.';
    }
    return 'هدوء وتركيز بين الصلوات.';
  }
}

class _HomeTaskEditDialog extends StatefulWidget {
  const _HomeTaskEditDialog({
    required this.task,
    this.schedule,
    this.slotMinutes,
  });

  final TaskItem task;
  final PrayerSchedule? schedule;
  final int? slotMinutes;

  @override
  State<_HomeTaskEditDialog> createState() => _HomeTaskEditDialogState();
}

class _HomeTaskEditDialogState extends State<_HomeTaskEditDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late PrayerPhase _prayer;
  late TaskType _type;
  late bool _useWindow;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late bool _enableReminder;
  late TimeOfDay _reminder;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t.title);
    _descriptionController = TextEditingController(text: t.description ?? '');
    _prayer = t.linkedPrayer;
    _type = t.type;
    final sm = t.startMinutesFromMidnight;
    final em = t.endMinutesFromMidnight;
    _useWindow = sm != null && em != null;
    if (_useWindow) {
      _start = TimeOfDay(hour: sm! ~/ 60, minute: sm % 60);
      _end = TimeOfDay(hour: em! ~/ 60, minute: em % 60);
    } else {
      _start = const TimeOfDay(hour: 9, minute: 0);
      _end = const TimeOfDay(hour: 10, minute: 0);
    }
    final rm = t.reminderMinutesFromMidnight;
    _enableReminder = rm != null;
    _reminder = _enableReminder
        ? TimeOfDay(hour: rm! ~/ 60, minute: rm % 60)
        : const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  int _toM(TimeOfDay td) => td.hour * 60 + td.minute;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل المهمة'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'الصلاة المرتبطة'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<PrayerPhase>(
                  isExpanded: true,
                  value: _prayer,
                  items: PrayerPhase.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.arabicName)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _prayer = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TaskType>(
              segments: const [
                ButtonSegment(value: TaskType.before, label: Text('قبل')),
                ButtonSegment(value: TaskType.after, label: Text('بعد')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('نافذة زمنية'),
              value: _useWindow,
              onChanged: (v) => setState(() => _useWindow = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('تفعيل تذكير للمهمة'),
              value: _enableReminder,
              onChanged: (v) => setState(() => _enableReminder = v),
            ),
            if (_enableReminder)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('وقت التذكير'),
                trailing: Text(_reminder.format(context)),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: _reminder);
                  if (p != null) setState(() => _reminder = p);
                },
              ),
            if (_useWindow) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('بدء'),
                trailing: Text(_start.format(context)),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: _start);
                  if (p != null) setState(() => _start = p);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('انتهاء'),
                trailing: Text(_end.format(context)),
                onTap: () async {
                  final p = await showTimePicker(context: context, initialTime: _end);
                  if (p != null) setState(() => _end = p);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: () {
            final sm = _useWindow ? _toM(_start) : null;
            final em = _useWindow ? _toM(_end) : null;
            if (_useWindow && em != null && sm != null && em <= sm) {
              appSnackTop(context, 'وقت الانتهاء بعد البدء');
              return;
            }
            final reminderM = _enableReminder ? _toM(_reminder) : null;
            if (widget.schedule != null &&
                widget.slotMinutes != null &&
                sm != null &&
                em != null) {
              final day = DateTime.now();
              final start = DateTime(day.year, day.month, day.day).add(Duration(minutes: sm));
              final end = DateTime(day.year, day.month, day.day).add(Duration(minutes: em));
              if (prayerSlotOverlaps(
                schedule: widget.schedule!,
                slotMinutes: widget.slotMinutes!,
                rangeStart: start,
                rangeEnd: end,
              )) {
                final suggested = nextAllowedMoment(
                  schedule: widget.schedule!,
                  slotMinutes: widget.slotMinutes!,
                  at: start,
                );
                appSnackTop(
                  context,
                  'لا يمكن الجدولة داخل وقت الصلاة. جرّب بعد ${DateFormat.jm('ar').format(suggested)}.',
                );
                return;
              }
            }
            if (widget.schedule != null && widget.slotMinutes != null && reminderM != null) {
              final day = DateTime.now();
              final at = DateTime(day.year, day.month, day.day).add(Duration(minutes: reminderM));
              if (prayerSlotOverlaps(
                schedule: widget.schedule!,
                slotMinutes: widget.slotMinutes!,
                rangeStart: at,
                rangeEnd: at.add(const Duration(minutes: 1)),
              )) {
                appSnackTop(context, 'وقت التذكير داخل وقت الصلاة.');
                return;
              }
            }
            Navigator.pop(
              context,
              widget.task.copyWith(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                linkedPrayer: _prayer,
                type: _type,
                startMinutesFromMidnight: sm,
                endMinutesFromMidnight: em,
                reminderMinutesFromMidnight: reminderM,
                clearTimeWindow: !_useWindow,
                clearReminder: !_enableReminder,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
