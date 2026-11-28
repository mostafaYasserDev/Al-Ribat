class PrayerSlotInfo {
  const PrayerSlotInfo({
    required this.label,
    required this.durationMinutes,
    required this.taskCount,
    required this.taskTitles,
  });

  final String label;
  final int durationMinutes;
  final int taskCount;
  final List<String> taskTitles;
}

class ReflectionSummary {
  const ReflectionSummary({
    required this.count,
    required this.periodDays,
    required this.topMoods,
    required this.recurringThemes,
    this.peakPrayerTime,
  });

  final int count;
  final int periodDays;
  final List<String> topMoods;
  final List<String> recurringThemes;
  final String? peakPrayerTime;

  String toReadableArabic() {
    if (count == 0) {
      return 'لا توجد تأملات مسجلة خلال آخر $periodDays أيام.';
    }
    final buf = StringBuffer()
      ..writeln('عدد التأملات خلال آخر $periodDays أيام: $count');
    if (topMoods.isNotEmpty) {
      buf.writeln('المشاعر المتكررة: ${topMoods.join("، ")}');
    }
    if (recurringThemes.isNotEmpty) {
      buf.writeln('المحاور المتكررة: ${recurringThemes.join("، ")}');
    }
    if (peakPrayerTime != null && peakPrayerTime!.isNotEmpty) {
      buf.writeln('أكثر وقت للكتابة: $peakPrayerTime');
    }
    return buf.toString().trim();
  }
}

class AiContextSnapshot {
  const AiContextSnapshot({
    this.currentTimeLabel,
    this.activitiesLines = const [],
    this.completedToday = 0,
    this.dueToday = 0,
    this.prayerLines = const [],
    this.prayerSlots = const [],
    this.projectLines = const [],
    this.fullReflectionLines = const [],
    this.reflectionSummary,
    this.workSessionLines = const [],
    this.totalFocusMinutesWeek = 0,
  });

  final String? currentTimeLabel;
  final List<String> activitiesLines;
  final int completedToday;
  final int dueToday;
  final List<String> prayerLines;
  final List<PrayerSlotInfo> prayerSlots;
  final List<String> projectLines;
  final List<String> fullReflectionLines;
  final ReflectionSummary? reflectionSummary;
  final List<String> workSessionLines;
  final int totalFocusMinutesWeek;

  String toPromptText() {
    final hasAnyData = activitiesLines.isNotEmpty ||
        dueToday > 0 ||
        prayerLines.isNotEmpty ||
        projectLines.isNotEmpty ||
        fullReflectionLines.isNotEmpty ||
        reflectionSummary != null ||
        workSessionLines.isNotEmpty ||
        totalFocusMinutesWeek > 0;
    if (!hasAnyData) {
      return 'لم يمنح المستخدم صلاحية مشاركة بيانات التطبيق بعد. قدّم نصائح عامة واحترم خصوصيته.';
    }

    final buf = StringBuffer();

    if (currentTimeLabel != null && currentTimeLabel!.isNotEmpty) {
      buf.writeln('اللحظة الحالية: $currentTimeLabel');
      buf.writeln();
    }

    if (prayerLines.isNotEmpty) {
      buf.writeln('## أوقات الصلاة اليوم:');
      for (final line in prayerLines) {
        buf.writeln('- $line');
      }
      if (prayerSlots.isNotEmpty) {
        buf.writeln('### الفترات بين الصلوات وتوزيع المهام:');
        for (final slot in prayerSlots) {
          final tasks =
              slot.taskTitles.isEmpty ? 'لا مهام' : slot.taskTitles.join('، ');
          buf.writeln(
            '- ${slot.label} (المدة ~${slot.durationMinutes} د، المهام: ${slot.taskCount}): $tasks',
          );
        }
      }
      buf.writeln();
    }

    if (activitiesLines.isNotEmpty || dueToday > 0) {
      buf.writeln(
          '## المهام والأنشطة (أُنجز اليوم $completedToday من $dueToday):');
      for (final line in activitiesLines) {
        buf.writeln('- $line');
      }
      buf.writeln();
    }

    if (projectLines.isNotEmpty) {
      buf.writeln('## المشاريع:');
      for (final line in projectLines) {
        buf.writeln('- $line');
      }
      buf.writeln();
    }

    if (fullReflectionLines.isNotEmpty) {
      buf.writeln('## التأملات الأخيرة (نص كامل بإذن المستخدم):');
      for (final line in fullReflectionLines) {
        buf.writeln('- $line');
      }
      buf.writeln();
    } else if (reflectionSummary != null) {
      buf.writeln('## ملخص التأملات (محلي مجرد بموافقة المستخدم):');
      buf.writeln(reflectionSummary!.toReadableArabic());
      buf.writeln();
    }

    if (workSessionLines.isNotEmpty || totalFocusMinutesWeek > 0) {
      buf.writeln(
          '## جلسات التركيز (إجمالي الأسبوع: $totalFocusMinutesWeek دقيقة):');
      for (final line in workSessionLines) {
        buf.writeln('- $line');
      }
      buf.writeln();
    }

    if (buf.isEmpty) {
      return 'لم يمنح المستخدم صلاحية مشاركة بيانات التطبيق بعد. قدّم نصائح عامة واحترم خصوصيته.';
    }
    return buf.toString().trim();
  }
}
