import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/ai_permissions.dart';
import '../domain/ai_provider_config.dart';

class AiSettingsHiveRepo {
  AiSettingsHiveRepo(this._box);

  final Box<String> _box;

  static const _configKey = 'ai_provider_config_v1';
  static const _permissionsKey = 'ai_permissions_v1';

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

  AiPermissions loadPermissions() {
    final raw = _box.get(_permissionsKey);
    if (raw == null || raw.isEmpty) return const AiPermissions();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AiPermissions.fromJson(decoded);
      }
    } catch (_) {}
    return const AiPermissions();
  }

  Future<void> savePermissions(AiPermissions permissions) async {
    await _box.put(_permissionsKey, jsonEncode(permissions.toJson()));
  }
}
