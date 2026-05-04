/// تنسيق متبقّي حتى وقت الصلاة بصيغة عربية طبيعية (ساعات ودقائق).
String formatArabicPrayerRemaining(Duration remaining) {
  if (remaining.isNegative || remaining.inSeconds <= 0) {
    return 'دخل وقت الصلاة';
  }
  final totalMin = remaining.inMinutes;
  final h = totalMin ~/ 60;
  final m = totalMin % 60;
  if (h == 0) {
    return m == 1 ? 'دقيقة واحدة متبقية' : '$m دقائق متبقية';
  }
  final hourPart = () {
    if (h == 1) return 'ساعة واحدة';
    if (h == 2) return 'ساعتان';
    if (h <= 10) return '$h ساعات';
    return '$h ساعة';
  }();
  if (m == 0) return '$hourPart متبقية';
  final minPart = m == 1 ? 'ودقيقة واحدة' : 'و$m دقائق';
  return '$hourPart $minPart متبقية';
}
