part of '../providers.dart';

String _statsFeedback({
  required int activitiesWeek,
  required int focusMin,
}) {
  if (activitiesWeek >= 12 && focusMin >= 60) {
    return 'أسبوع متوازن بين الأنشطة والتركيز — تابع على هذا المنوال.';
  }
  if (activitiesWeek >= 6) {
    return 'إيقاع جيد. حاول إضافة جلسة تركيز قصيرة بين الحصص.';
  }
  return 'ابدأ بخطوة صغيرة بعد كل صلاة؛ التراكم يصنع الفارق.';
}

PrayerPhase? _mostProductivePhase(Map<PrayerPhase, int> byPhase) {
  PrayerPhase? productivePhase;
  var maxCount = -1;
  for (final entry in byPhase.entries) {
    if (entry.value > maxCount && entry.value > 0) {
      maxCount = entry.value;
      productivePhase = entry.key;
    }
  }
  return productivePhase;
}

String? _mostSkippedActivity(Map<String, int> skipsByActivity) {
  String? mostSkipped;
  var maxSkips = -1;
  for (final entry in skipsByActivity.entries) {
    if (entry.value > maxSkips) {
      maxSkips = entry.value;
      mostSkipped = entry.key;
    }
  }
  return mostSkipped;
}
