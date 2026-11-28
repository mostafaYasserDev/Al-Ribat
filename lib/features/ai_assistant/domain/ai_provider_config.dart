enum AiProviderType { groqCloud, localLlm }

class AiProviderConfig {
  const AiProviderConfig({
    this.type = AiProviderType.groqCloud,
    this.groqApiKey,
    this.groqModel = defaultGroqModel,
    this.localModelId,
    this.localModelPath,
    this.hasCompletedOnboarding = false,
  });

  static const String defaultGroqModel = 'llama-3.3-70b-versatile';
  static const String fastGroqModel = 'llama-3.1-8b-instant';

  final AiProviderType type;
  final String? groqApiKey;
  final String groqModel;
  final String? localModelId;
  final String? localModelPath;
  final bool hasCompletedOnboarding;

  bool get isConfigured => switch (type) {
        AiProviderType.groqCloud =>
          groqApiKey != null && groqApiKey!.trim().isNotEmpty,
        AiProviderType.localLlm =>
          localModelPath != null && localModelPath!.trim().isNotEmpty,
      };

  AiProviderConfig copyWith({
    AiProviderType? type,
    String? groqApiKey,
    bool clearGroqApiKey = false,
    String? groqModel,
    String? localModelId,
    String? localModelPath,
    bool? hasCompletedOnboarding,
  }) {
    return AiProviderConfig(
      type: type ?? this.type,
      groqApiKey: clearGroqApiKey ? null : (groqApiKey ?? this.groqApiKey),
      groqModel: groqModel ?? this.groqModel,
      localModelId: localModelId ?? this.localModelId,
      localModelPath: localModelPath ?? this.localModelPath,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'groqApiKey': groqApiKey,
        'groqModel': groqModel,
        'localModelId': localModelId,
        'localModelPath': localModelPath,
        'hasCompletedOnboarding': hasCompletedOnboarding,
      };

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type =
        AiProviderType.values.where((e) => e.name == typeName).firstOrNull ??
            AiProviderType.groqCloud;
    return AiProviderConfig(
      type: type,
      groqApiKey: json['groqApiKey'] as String?,
      groqModel: json['groqModel'] as String? ?? defaultGroqModel,
      localModelId: json['localModelId'] as String?,
      localModelPath: json['localModelPath'] as String?,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
    );
  }
}
