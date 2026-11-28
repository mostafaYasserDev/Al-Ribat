enum ArabicQuality { acceptable, good, excellent }

class LocalModelSpec {
  const LocalModelSpec({
    required this.id,
    required this.displayName,
    required this.badge,
    required this.description,
    required this.sizeMb,
    required this.requiredRamMb,
    required this.arabicQuality,
    required this.speedNote,
  });

  final String id;
  final String displayName;
  final String badge;
  final String description;
  final int sizeMb;
  final int requiredRamMb;
  final ArabicQuality arabicQuality;
  final String speedNote;

  String get arabicQualityLabel => switch (arabicQuality) {
        ArabicQuality.acceptable => 'مقبولة',
        ArabicQuality.good => 'جيدة',
        ArabicQuality.excellent => 'ممتازة',
      };

  /// Curated 3-model catalog for Phase 4 local inference.
  static const List<LocalModelSpec> catalog = [
    LocalModelSpec(
      id: 'qwen-0.5b-q4',
      displayName: 'Qwen 2.5 0.5B (Q4)',
      badge: 'خفيف',
      description:
          'الأخف والأسرع على الأجهزة الاقتصادية، مناسب للاستفسارات السريعة.',
      sizeMb: 400,
      requiredRamMb: 1200,
      arabicQuality: ArabicQuality.acceptable,
      speedNote: 'سريع جداً',
    ),
    LocalModelSpec(
      id: 'gemma3-1b-int4',
      displayName: 'Gemma 3 1B (INT4)',
      badge: 'متوازن',
      description: 'توازن ممتاز بين السرعة وجودة العربية لمعظم الهواتف.',
      sizeMb: 530,
      requiredRamMb: 1800,
      arabicQuality: ArabicQuality.good,
      speedNote: 'سريع',
    ),
    LocalModelSpec(
      id: 'llama32-3b-q4',
      displayName: 'Llama 3.2 3B (Q4)',
      badge: 'ذكي',
      description:
          'فهم أعمق وجودة عالية في التخطيط والنقاش، يحتاج جهازاً بذاكرة أكبر.',
      sizeMb: 1900,
      requiredRamMb: 3500,
      arabicQuality: ArabicQuality.excellent,
      speedNote: 'متوسط',
    ),
  ];
}
