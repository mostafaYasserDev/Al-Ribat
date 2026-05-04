import 'dart:math';

/// Short Arabic lines for habit reminders (deterministic pick by [seed]).
class MotivationQuotes {
  static const _lines = <String>[
    'خطوة صغيرة اليوم تبني عادة الغد.',
    'ثباتك أثمن من اندفاعك؛ واصل بهدوء.',
    'النية الصافية تجعل العمل أخف.',
    'لا تؤجل ما يقوّي روحك دقيقة واحدة.',
    'من جدّ وجد، ومن زرع حصد.',
    'بارك الله في وقتك؛ ابدأ الآن.',
    'العادة الحسنة صدقة على نفسك كل يوم.',
    'ما خاب من استعان بالله ثم بسعيه.',
  ];

  static String pickFor(String seed) {
    final hash = seed.hashCode.abs();
    return _lines[hash % _lines.length];
  }

  static String randomLine() {
    return _lines[Random().nextInt(_lines.length)];
  }
}
