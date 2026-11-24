/// بداية الأسبوع وفق العرف العربي/الإسلامي (السبت).
DateTime weekStartSaturday(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final daysSinceSaturday = (normalized.weekday % 7 + 1) % 7;
  return DateTime(
    normalized.year,
    normalized.month,
    normalized.day - daysSinceSaturday,
  );
}
