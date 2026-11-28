enum AiRole { user, assistant, system }

class AiMessage {
  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
  });

  final String id;
  final AiRole role;
  final String content;
  final DateTime createdAt;
  final bool isError;

  AiMessage copyWith({
    String? content,
    bool? isError,
  }) {
    return AiMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      createdAt: createdAt,
      isError: isError ?? this.isError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isError': isError,
      };

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String?;
    final role = AiRole.values.where((e) => e.name == roleName).firstOrNull ??
        AiRole.assistant;
    return AiMessage(
      id: json['id'] as String,
      role: role,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isError: json['isError'] as bool? ?? false,
    );
  }
}
