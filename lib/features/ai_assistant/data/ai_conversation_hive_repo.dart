import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/ai_chat_session.dart';
import '../domain/ai_message.dart';

class AiConversationHiveRepo {
  AiConversationHiveRepo(this._box);

  final Box<String> _box;

  static const _legacyHistoryKey = 'ai_chat_history_v1';
  static const _sessionsKey = 'ai_chat_sessions_v1';
  static const _activeSessionKey = 'ai_active_session_id_v1';
  static const int _maxStoredMessages = 60;
  static const int _maxSessions = 20;

  List<AiChatSession> loadSessions() {
    final raw = _box.get(_sessionsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List<dynamic>) {
          final list = decoded
              .whereType<Map<String, dynamic>>()
              .map(AiChatSession.fromJson)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (list.isNotEmpty) return list;
        }
      } catch (_) {}
    }

    // Migrate legacy single-thread history if present.
    final legacy = loadAll();
    if (legacy.isNotEmpty) {
      final firstUser =
          legacy.where((m) => m.role == AiRole.user).firstOrNull?.content ??
              'محادثة سابقة';
      final title =
          firstUser.length > 34 ? '${firstUser.substring(0, 34)}…' : firstUser;
      return [
        AiChatSession(
          id: 'session_migrated',
          title: title,
          updatedAt: legacy.last.createdAt,
          messages: legacy,
        ),
      ];
    }

    return const [];
  }

  Future<void> saveSessions(List<AiChatSession> sessions) async {
    final trimmedSessions = sessions.take(_maxSessions).map((s) {
      final msgs = s.messages.length > _maxStoredMessages
          ? s.messages.sublist(s.messages.length - _maxStoredMessages)
          : s.messages;
      return s.copyWith(messages: msgs);
    }).toList();
    await _box.put(
      _sessionsKey,
      jsonEncode(trimmedSessions.map((s) => s.toJson()).toList()),
    );
  }

  String? getActiveSessionId() => _box.get(_activeSessionKey);

  Future<void> setActiveSessionId(String id) async {
    await _box.put(_activeSessionKey, id);
  }

  List<AiMessage> loadAll() {
    final raw = _box.get(_legacyHistoryKey);
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
    await _box.put(_legacyHistoryKey, payload);
  }

  Future<void> clear() async {
    await _box.delete(_legacyHistoryKey);
  }
}
