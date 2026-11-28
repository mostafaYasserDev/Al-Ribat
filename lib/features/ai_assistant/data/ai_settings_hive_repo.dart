import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/ai_permissions.dart';
import '../domain/ai_provider_config.dart';

class AiSettingsHiveRepo {
  AiSettingsHiveRepo(this._box);

  final Box<String> _box;

  static const _configKey = 'ai_provider_config_v1';
  static const _legacyPermissionsKey = 'ai_permissions_v1';
  static const _cloudPermissionsKey = 'ai_permissions_cloud_v1';
  static const _localPermissionsKey = 'ai_permissions_local_v1';

  AiProviderConfig loadConfig() {
    final raw = _box.get(_configKey);
    if (raw == null || raw.isEmpty) return const AiProviderConfig();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AiProviderConfig.fromJson(decoded);
      }
    } catch (_) {}
    return const AiProviderConfig();
  }

  Future<void> saveConfig(AiProviderConfig config) async {
    await _box.put(_configKey, jsonEncode(config.toJson()));
  }

  AiPermissions loadPermissions(
      [AiProviderType type = AiProviderType.groqCloud]) {
    final key = type == AiProviderType.localLlm
        ? _localPermissionsKey
        : _cloudPermissionsKey;
    final raw = _box.get(key) ?? _box.get(_legacyPermissionsKey);
    if (raw == null || raw.isEmpty) {
      return type == AiProviderType.localLlm
          ? const AiPermissions(
              allowReflections: false,
              allowReflectionSummary: true,
            )
          : const AiPermissions();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AiPermissions.fromJson(decoded);
      }
    } catch (_) {}
    return const AiPermissions();
  }

  Future<void> savePermissions(
    AiPermissions permissions, [
    AiProviderType type = AiProviderType.groqCloud,
  ]) async {
    final key = type == AiProviderType.localLlm
        ? _localPermissionsKey
        : _cloudPermissionsKey;
    await _box.put(key, jsonEncode(permissions.toJson()));
  }
}
