import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../application/providers.dart';
import '../../../core/activity_schedule.dart';
import '../../../core/constants/prayer_phase.dart';
import '../../../core/ui_feedback.dart';
import '../../../domain/entities/app_settings.dart';
import '../../../domain/entities/activity_item.dart';
import '../../../domain/entities/prayer_schedule.dart';
import '../../../domain/entities/prayer_time.dart';
import '../../../services/motivation_quotes.dart';
import '../../widgets/prayer_card.dart';
import '../../widgets/reflection_card.dart';
import '../../widgets/independent_activities_card.dart';

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


void openDayDetailsSheet({
  required BuildContext context,
  required PrayerSchedule schedule,
  required AppSettings settings,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final activities = ref.watch(activitiesProvider).valueOrNull ?? const <ActivityItem>[];
          final dayState = ref.watch(dayStateProvider);
          final currentPhase = dayState.currentPrayerPhase;
          final selectedDate = ref.watch(selectedDateProvider);
          final todayStr = DateFormat('yyyy-MM-dd').format(selectedDate);
          final independentActs = independentActivities(activities, selectedDate);

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
                    if (independentActs.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IndependentActivitiesCard(
                          dateStr: todayStr,
                          activities: independentActs,
                          onToggleActivity: (activity, date) async {
                            HapticFeedback.selectionClick();
                            final wasDone = activity.isDoneOn(date);
                            await ref.read(activitiesProvider.notifier).toggleDone(activity, date);
                            if (!wasDone && context.mounted) {
                              showCelebration(context, MotivationQuotes.randomLine());
                            }
                          },
                          onSkipActivity: (activity, date) async {
                            await ref.read(activitiesProvider.notifier).toggleSkip(activity, date);
                            if (context.mounted) {
                              appSnack(context, 'تم تخطي النشاط لهذا اليوم.');
                            }
                          },
                          onDeleteActivity: (activity) async {
                            await ref.read(activitiesProvider.notifier).deleteActivity(activity.id);
                            if (context.mounted) {
                              appSnack(context, 'تم حذف النشاط.');
                            }
                          },
                          onEditActivity: (updated) async {
                            await ref.read(activitiesProvider.notifier).updateActivity(updated);
                            if (context.mounted) appSnack(context, 'تم تعديل النشاط.');
                          },
                          onAddProgressActivity: (activity, date, amount) async {
                            final wasDone = activity.isDoneOn(date);
                            await ref.read(activitiesProvider.notifier).addProgress(activity, date, amount);
                            if (context.mounted && !wasDone) {
                              final acts = ref.read(activitiesProvider).valueOrNull ?? [];
                              final u = acts.firstWhere((a) => a.id == activity.id, orElse: () => activity);
                              if (u.isDoneOn(date)) {
                                showCelebration(context, MotivationQuotes.randomLine());
                              }
                            }
                          },
                          onReorder: (movedActivity, newIndex) {
                            ref.read(activitiesProvider.notifier).reorder(movedActivity, newIndex, independentActs);
                          },
                        ),
                      ),
                    ...schedule.today.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PrayerCard(
                          dateStr: todayStr,
                          prayer: p,
                          prayerSchedule: schedule,
                          footerNote: _betweenAdhanSentence(p, schedule),
                          activities: activitiesForPhase(activities, p.phase, selectedDate),
                          onToggleActivity: (activity, date) async {
                            HapticFeedback.selectionClick();
                            final wasDone = activity.isDoneOn(date);
                            await ref.read(activitiesProvider.notifier).toggleDone(activity, date);
                            if (!wasDone && context.mounted) {
                              showCelebration(context, MotivationQuotes.randomLine());
                            }
                          },
                          onSkipActivity: (activity, date) async {
                            await ref.read(activitiesProvider.notifier).toggleSkip(activity, date);
                            if (context.mounted) {
                              appSnack(context, 'تم تخطي النشاط لهذا اليوم.');
                            }
                          },
                          onDeleteActivity: (activity) async {
                            await ref.read(activitiesProvider.notifier).deleteActivity(activity.id);
                            if (context.mounted) {
                              appSnack(context, 'تم حذف النشاط.');
                            }
                          },
                          onEditActivity: (updated) async {
                            await ref.read(activitiesProvider.notifier).updateActivity(updated);
                            if (context.mounted) appSnack(context, 'تم تعديل النشاط.');
                          },
                          onAddProgressActivity: (activity, date, amount) async {
                            final wasDone = activity.isDoneOn(date);
                            await ref.read(activitiesProvider.notifier).addProgress(activity, date, amount);
                            if (context.mounted && !wasDone) {
                              final acts = ref.read(activitiesProvider).valueOrNull ?? [];
                              final u = acts.firstWhere((a) => a.id == activity.id, orElse: () => activity);
                              if (u.isDoneOn(date)) {
                                showCelebration(context, MotivationQuotes.randomLine());
                              }
                            }
                          },
                          onReorderWithinPhase: (movedActivity, newIndex) {
                            final phaseActivities = activitiesForPhase(activities, p.phase, selectedDate);
                            ref.read(activitiesProvider.notifier).reorder(movedActivity, newIndex, phaseActivities);
                          },
                        ),
                      ),
                    ),
                    if (currentPhase == PrayerPhase.isha || todayStr != DateFormat('yyyy-MM-dd').format(DateTime.now()))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ReflectionCard(
                          streakCount: max(ref.watch(dayStateProvider).streakCount, 1),
                          onSave: (value, mood) async {
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
            ),
          );
        },
      );
    },
  );
}
