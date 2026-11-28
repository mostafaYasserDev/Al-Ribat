import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../application/providers.dart';
import '../data/local_context_builder.dart';
import '../domain/ai_context_snapshot.dart';
import '../domain/ai_permissions.dart';
import '../domain/ai_proactive_alert.dart';
import 'ai_providers.dart';

class AiProactiveEngine {
  const AiProactiveEngine();

  /// Analyzes the user's permitted context purely locally (zero LLM cost).
  AiProactiveAlert? evaluate(
    AiContextSnapshot snapshot,
    AiPermissions perms, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    // 1. Detect overloaded short prayer slots (e.g. Maghrib -> Isha).
    if (perms.allowPrayer && perms.allowActivities) {
      for (final slot in snapshot.prayerSlots) {
        final isTight = (slot.durationMinutes <= 105 && slot.taskCount >= 3) ||
            (slot.durationMinutes <= 70 && slot.taskCount >= 2);
        if (isTight) {
          return AiProactiveAlert(
            id: 'slot_${slot.label}',
            type: ProactiveAlertType.schedulingConflict,
            title: 'جدولة مزدحمة ${slot.label}',
            body:
                'لديك ${slot.taskCount} مهام في فترة ~${slot.durationMinutes} دقيقة فقط. هل نعيد توزيعها لتخفيف الضغط؟',
            suggestedPrompt:
                'لدي ${slot.taskCount} مهام ${slot.label} (${slot.durationMinutes} دقيقة فقط): ${slot.taskTitles.join("، ")}. اقترح لي إعادة توزيع مناسبة على بقية الصلوات.',
          );
        }
      }
    }

    // 2. Late-day gentle commitment nudge when several tasks remain undone.
    if (perms.allowActivities &&
        current.hour >= 16 &&
        snapshot.dueToday >= 4 &&
        snapshot.completedToday == 0) {
      return AiProactiveAlert(
        id: 'nudge_late_day',
        type: ProactiveAlertType.commitmentNudge,
        title: 'يوم حافل بالمهام (${snapshot.dueToday} مهام)',
        body:
            'لم يُنجز أي نشاط بعد مع اقتراب المساء. هل نرتب الأولويات لتنجز أهمها اليوم؟',
        suggestedPrompt:
            'لدي ${snapshot.dueToday} مهام متبقية اليوم ولم أبدأ بعد. رتب لي أولوياتها بخطة واقعية قبل النوم.',
      );
    }

    // 3. Focus balance suggestion when tasks exist but weekly focus is 0.
    if (perms.allowWorkSessions &&
        perms.allowActivities &&
        snapshot.dueToday >= 2 &&
        snapshot.totalFocusMinutesWeek == 0) {
      return const AiProactiveAlert(
        id: 'focus_balance_zero',
        type: ProactiveAlertType.focusBalance,
        title: 'جرّب جلسة تركيز قصيرة',
        body:
            'لم تسجل جلسات تركيز هذا الأسبوع بعد. تقسيم مهامك إلى جلسة 25 دقيقة قد يرفع إنجازك.',
        suggestedPrompt:
            'اقترح لي كيف أستخدم جلسات التركيز لإنجاز مهامي اليوم بدون إرهاق.',
      );
    }

    return null;
  }
}

final aiDismissedAlertsProvider =
    NotifierProvider<AiDismissedAlertsNotifier, Set<String>>(
  AiDismissedAlertsNotifier.new,
);

class AiDismissedAlertsNotifier extends Notifier<Set<String>> {
  static const _key = 'ai_dismissed_alerts_v1';

  String _todayPrefix() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_';
  }

  @override
  Set<String> build() {
    final box = Hive.box<String>('meta_box');
    final raw = box.get(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) {
        final prefix = _todayPrefix();
        return decoded
            .map((e) => e.toString())
            .where((e) => e.startsWith(prefix))
            .toSet();
      }
    } catch (_) {}
    return const {};
  }

  Future<void> dismissForToday(String alertId) async {
    final token = '${_todayPrefix()}$alertId';
    final next = {...state, token};
    state = next;
    await Hive.box<String>('meta_box').put(_key, jsonEncode(next.toList()));
  }

  bool isDismissedToday(String alertId) {
    return state.contains('${_todayPrefix()}$alertId');
  }
}

final aiProactiveAlertProvider = Provider<AiProactiveAlert?>((ref) {
  final config = ref.watch(aiConfigProvider);
  if (!config.proactiveAlertsEnabled) return null;

  final perms = ref.watch(aiPermissionsProvider);
  final dismissed = ref.watch(aiDismissedAlertsProvider);
  final activities = ref.watch(activitiesProvider).valueOrNull ?? const [];
  final schedule = ref.watch(prayerScheduleProvider).valueOrNull;
  final reflections = ref.watch(reflectionsProvider).valueOrNull ?? const [];
  final sessions = ref.watch(workSessionsProvider).valueOrNull ?? const [];

  const builder = LocalContextBuilder();
  final snapshot = builder.build(
    permissions: perms,
    activities: activities,
    prayerSchedule: schedule,
    reflections: reflections,
    workSessions: sessions,
  );

  const engine = AiProactiveEngine();
  final alert = engine.evaluate(snapshot, perms);
  if (alert == null) return null;

  final now = DateTime.now();
  final todayToken =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${alert.id}';
  if (dismissed.contains(todayToken)) return null;

  return alert;
});
