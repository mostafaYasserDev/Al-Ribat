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
    required this.fileName,
    required this.downloadUrl,
  });

  final String id;
  final String displayName;
  final String badge;
  final String description;
  final int sizeMb;
  final int requiredRamMb;
  final ArabicQuality arabicQuality;
  final String speedNote;
  final String fileName;
  final String downloadUrl;

  String get arabicQualityLabel => switch (arabicQuality) {
        ArabicQuality.acceptable => 'مقبولة',
        ArabicQuality.good => 'جيدة',
        ArabicQuality.excellent => 'ممتازة',
      };

  /// Curated 3-model catalog for local on-device inference (GGUF).
  static const List<LocalModelSpec> catalog = [
    LocalModelSpec(
      id: 'qwen-1.5b-q4',
      displayName: 'Qwen 2.5 1.5B (Q4)',
      badge: 'خفيف',
      description: 'أسرع نموذج يدعم العربية بوضوح ومناسب لمعظم الهواتف.',
      sizeMb: 980,
      requiredRamMb: 2200,
      arabicQuality: ArabicQuality.good,
      speedNote: 'سريع',
      fileName: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    ),
    LocalModelSpec(
      id: 'gemma3-1b-int4',
      displayName: 'Gemma 3 1B (Q4)',
      badge: 'متوازن',
      description: 'توازن ممتاز بين السرعة وجودة العربية لمعظم الهواتف.',
      sizeMb: 530,
      requiredRamMb: 1800,
      arabicQuality: ArabicQuality.good,
      speedNote: 'سريع',
      fileName: 'gemma-3-1b-it-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/unsloth/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf',
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
      fileName: 'Llama-3.2-3B-Instruct-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf',
    ),
  ];
}
