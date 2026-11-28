import 'ai_message.dart';

class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.messages = const [],
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final List<AiMessage> messages;

  AiChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<AiMessage>? messages,
  }) {
    return AiChatSession(
      id: id,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory AiChatSession.fromJson(Map<String, dynamic> json) {
    final rawMsgs = json['messages'] as List<dynamic>? ?? const [];
    return AiChatSession(
      id: json['id'] as String? ?? 'default',
      title: json['title'] as String? ?? 'محادثة جديدة',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      messages: rawMsgs
          .whereType<Map<String, dynamic>>()
          .map(AiMessage.fromJson)
          .toList(),
    );
  }
}
