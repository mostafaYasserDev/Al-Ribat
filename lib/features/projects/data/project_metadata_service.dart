import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../domain/project_models.dart';

class ProjectGroupsService {
  static const _prefix = 'proj_groups_meta_';
  static const _infoPrefix = 'proj_info_';

  static Box<String>? _getBox() {
    return Hive.isBoxOpen('meta_box') ? Hive.box<String>('meta_box') : null;
  }

  static List<ProjectGroupInfo> getGroups(String projectName) {
    final box = _getBox();
    if (box == null) return [];
    final raw = box.get('$_prefix$projectName');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ProjectGroupInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGroup(
    String projectName,
    String groupName,
    String? description,
  ) async {
    final box = _getBox();
    if (box == null) return;
    final current = getGroups(projectName);
    final idx = current.indexWhere((g) => g.name == groupName);
    final updated = List<ProjectGroupInfo>.from(current);
    if (idx >= 0) {
      updated[idx] =
          ProjectGroupInfo(name: groupName, description: description);
    } else {
      updated.add(ProjectGroupInfo(name: groupName, description: description));
    }
    await box.put(
      '$_prefix$projectName',
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  static ProjectDetailsInfo? getProjectInfo(String projectName) {
    final box = _getBox();
    if (box == null) return null;
    final raw = box.get('$_infoPrefix$projectName');
    if (raw == null) return null;
    try {
      return ProjectDetailsInfo.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProjectInfo(
    String projectName, {
    String? description,
    String? iconName,
    String? colorHex,
  }) async {
    final box = _getBox();
    if (box == null) return;
    final info = ProjectDetailsInfo(
      description: description,
      iconName: iconName,
      colorHex: colorHex,
    );
    await box.put('$_infoPrefix$projectName', jsonEncode(info.toJson()));
    if (box.get('$_prefix$projectName') == null) {
      await box.put('$_prefix$projectName', jsonEncode([]));
    }
  }

  static List<String> getAllProjectNames() {
    final box = _getBox();
    if (box == null) return [];
    final names = <String>{};
    for (final k in box.keys.whereType<String>()) {
      if (k.startsWith(_prefix)) {
        names.add(k.substring(_prefix.length));
      } else if (k.startsWith(_infoPrefix)) {
        names.add(k.substring(_infoPrefix.length));
      }
    }
    return names.toList();
  }

  static Future<void> deleteProjectMeta(String projectName) async {
    final box = _getBox();
    if (box == null) return;
    await box.delete('$_prefix$projectName');
    await box.delete('$_infoPrefix$projectName');
  }

  static Future<void> deleteGroup(String projectName, String groupName) async {
    final box = _getBox();
    if (box == null) return;
    final current = getGroups(projectName);
    final updated = current.where((g) => g.name != groupName).toList();
    await box.put(
      '$_prefix$projectName',
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> renameGroup(
    String projectName,
    String oldName,
    String newName,
  ) async {
    final box = _getBox();
    if (box == null) return;
    final current = getGroups(projectName);
    final updated = current
        .map((g) => g.name == oldName
            ? ProjectGroupInfo(name: newName, description: g.description)
            : g)
        .toList();
    if (!updated.any((g) => g.name == newName)) {
      updated.add(ProjectGroupInfo(name: newName));
    }
    await box.put(
      '$_prefix$projectName',
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }
}
