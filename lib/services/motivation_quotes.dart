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
    'قليل دائم خير من كثير منقطع.',
    'الاستمرارية تصنع المعجزات.',
    'بادر قبل أن تغادر.',
  ];

  static const _emptyLines = <String>[
    'وقتك الآن ثمين، استثمره في إضافة نشاط ينفعك.',
    'لحظات الفراغ فرصة لزرع عادة جديدة مفيدة.',
    'لا تترك يومك يمر دون إنجاز، أضف نشاطاً الآن!',
    'ما رأيك في إضافة عادة صغيرة تغير مسار يومك؟',
    'استثمر هدوء هذه اللحظة في تحديد هدف بسيط.',
    'الصفحة بيضاء، أنت من يقرر ما سيكتب فيها اليوم.',
    'لا بأس بوقت مستقطع، لكن اجعل ما بعده إضافة مثمرة.',
  ];

  static String pickFor(String seed) {
    final hash = seed.hashCode.abs();
    return _lines[hash % _lines.length];
  }

  static String randomLine() {
    return _lines[Random().nextInt(_lines.length)];
  }

  static String randomEmptyLine() {
    return _emptyLines[Random().nextInt(_emptyLines.length)];
  }
}
