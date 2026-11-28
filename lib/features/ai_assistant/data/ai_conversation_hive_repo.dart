import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/ai_message.dart';

class AiConversationHiveRepo {
  AiConversationHiveRepo(this._box);

  final Box<String> _box;

  static const _historyKey = 'ai_chat_history_v1';
  static const int _maxStoredMessages = 60;

  List<AiMessage> loadAll() {
    final raw = _box.get(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List<dynamic>) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(AiMessage.fromJson)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> saveAll(List<AiMessage> messages) async {
    final trimmed = messages.length > _maxStoredMessages
        ? messages.sublist(messages.length - _maxStoredMessages)
        : messages;
    final payload = jsonEncode(trimmed.map((m) => m.toJson()).toList());
    await _box.put(_historyKey, payload);
  }

  Future<void> clear() async {
    await _box.delete(_historyKey);
  }
}
