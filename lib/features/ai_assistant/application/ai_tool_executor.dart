import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/constants/prayer_phase.dart';
import '../../activities/domain/activity_item.dart';
import '../../projects/data/project_metadata_service.dart';
import '../domain/ai_tool_call.dart';

class AiToolExecutor {
  const AiToolExecutor();

  Future<void> execute(Ref ref, AiToolCall call) async {
    final now = DateTime.now();
    switch (call) {
      case AddActivityToolCall():
        final activity = ActivityItem(
          id: 'ai_${now.microsecondsSinceEpoch}',
          title: call.title,
          repetition: _parseRepetition(call.repetition),
          type: _parseType(call.type),
          linkedPrayer: _parsePrayer(call.linkedPrayer),
          projectName:
              call.projectName?.isNotEmpty == true ? call.projectName : null,
          createdAt: now,
        );
        await ref.read(activitiesProvider.notifier).addActivity(activity);

      case CreateProjectToolCall():
        await ProjectGroupsService.saveProjectInfo(
          call.name,
          description: call.description,
        );
        if (call.tasks.isNotEmpty) {
          final items = [
            for (var i = 0; i < call.tasks.length; i++)
              ActivityItem(
                id: 'ai_proj_${now.microsecondsSinceEpoch}_$i',
                title: call.tasks[i],
                repetition: ActivityRepetition.open,
                projectName: call.name,
                createdAt: now,
              ),
          ];
          await ref
              .read(activitiesProvider.notifier)
              .addMultipleActivities(items);
        }
    }
  }

  ActivityRepetition _parseRepetition(String value) => switch (value) {
        'once' => ActivityRepetition.once,
        'weekly' => ActivityRepetition.weekly,
        'monthly' => ActivityRepetition.monthly,
        'open' => ActivityRepetition.open,
        _ => ActivityRepetition.daily,
      };

  ActivityType _parseType(String value) => switch (value) {
        'beforePrayer' => ActivityType.beforePrayer,
        'afterPrayer' => ActivityType.afterPrayer,
        _ => ActivityType.independent,
      };

  PrayerPhase? _parsePrayer(String? value) => switch (value) {
        'fajr' => PrayerPhase.fajr,
        'dhuhr' => PrayerPhase.dhuhr,
        'asr' => PrayerPhase.asr,
        'maghrib' => PrayerPhase.maghrib,
        'isha' => PrayerPhase.isha,
        _ => null,
      };
}
