import 'constants/prayer_phase.dart';
import '../domain/entities/prayer_schedule.dart';
import '../domain/entities/prayer_time.dart';

class ArabicTimeFormatter {
  const ArabicTimeFormatter._();

  /// تنسيق متبقّي حتى وقت الصلاة بصيغة عربية طبيعية (ساعات ودقائق).
  static String formatRemaining(Duration remaining) {
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

  /// صياغة المدة بين أذانين متتاليين.
  static String betweenPrayersSentence(
      PrayerTime current, PrayerSchedule schedule) {
    final idx = schedule.today.indexWhere((p) => p.phase == current.phase);
    final next = (idx >= 0 && idx < schedule.today.length - 1)
        ? schedule.today[idx + 1]
        : schedule.tomorrowFajr;
    final d = next.time.difference(current.time);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final duration =
        h > 0 ? '$h ساعة${m > 0 ? ' و $m دقيقة' : ''}' : '$m دقيقة';
    return 'بين أذان ${current.phase.arabicName} و${next.phase.arabicName}: $duration';
  }
}

/// توافقية عكسية
String formatArabicPrayerRemaining(Duration remaining) =>
    ArabicTimeFormatter.formatRemaining(remaining);
