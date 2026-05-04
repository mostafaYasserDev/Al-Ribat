import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupExportService {
  static Future<String> buildJsonString() async {
    final meta = Hive.box<String>('meta_box');
    final tasksBox = Hive.box<String>('tasks_box');
    final habitsBox = Hive.box<String>('habits_box');
    final reflBox = Hive.box<String>('reflections_box');
    final workBox = Hive.box<String>('work_sessions_box');

    final payload = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settingsJson': meta.get('settings'),
      'tasks': tasksBox.values.toList(),
      'habits': habitsBox.values.toList(),
      'reflections': reflBox.values.toList(),
      'workSessions': workBox.values.toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Future<void> exportInteractive() async {
    final json = await buildJsonString();
    final name = 'al_ribat_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/$name';
        final file = File(path);
        await file.writeAsString(json, flush: true);
        await Share.shareXFiles([XFile(path)], subject: name);
        return;
      } catch (e, st) {
        debugPrint('BackupExportService shareXFiles: $e\n$st');
      }

      try {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ النسخة الاحتياطية',
          fileName: name,
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
        if (path != null) {
          final p = path.toLowerCase().endsWith('.json') ? path : '$path.json';
          await File(p).writeAsString(json);
          return;
        }
      } catch (e, st) {
        debugPrint('BackupExportService saveFile: $e\n$st');
      }
    }

    await Share.share(json, subject: name);
  }

  static Future<void> importInteractive() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'اختر ملف النسخة الاحتياطية',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      throw Exception('تم إلغاء اختيار الملف.');
    }
    final file = picked.files.single;
    String? raw = file.bytes == null ? null : utf8.decode(file.bytes!);
    final path = file.path;
    if ((raw == null || raw.trim().isEmpty) && path != null) {
      raw = await File(path).readAsString();
    }
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('الملف فارغ أو غير قابل للقراءة.');
    }
    await _restoreFromJson(raw);
  }

  static Future<void> _restoreFromJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('هيكلة الملف غير صحيحة.');
    }
    final v = decoded['version'];
    if (v is! int || v != 1) {
      throw const FormatException('إصدار النسخة غير مدعوم.');
    }
    if (!decoded.containsKey('tasks') ||
        !decoded.containsKey('habits') ||
        !decoded.containsKey('reflections') ||
        !decoded.containsKey('workSessions') ||
        !decoded.containsKey('settingsJson')) {
      throw const FormatException('الملف لا يطابق هيكلة التصدير.');
    }
    final tasks = _asStringList(decoded['tasks'], key: 'tasks');
    final habits = _asStringList(decoded['habits'], key: 'habits');
    final reflections = _asStringList(decoded['reflections'], key: 'reflections');
    final workSessions = _asStringList(decoded['workSessions'], key: 'workSessions');

    final settingsRaw = decoded['settingsJson'];
    if (settingsRaw != null && settingsRaw is! String) {
      throw const FormatException('settingsJson يجب أن يكون نصاً أو null.');
    }

    final meta = Hive.box<String>('meta_box');
    final tasksBox = Hive.box<String>('tasks_box');
    final habitsBox = Hive.box<String>('habits_box');
    final reflBox = Hive.box<String>('reflections_box');
    final workBox = Hive.box<String>('work_sessions_box');

    await tasksBox.clear();
    await habitsBox.clear();
    await reflBox.clear();
    await workBox.clear();

    for (final item in tasks) {
      await tasksBox.add(item);
    }
    for (final item in habits) {
      await habitsBox.add(item);
    }
    for (final item in reflections) {
      await reflBox.add(item);
    }
    for (final item in workSessions) {
      await workBox.add(item);
    }

    if (settingsRaw == null) {
      await meta.delete('settings');
    } else {
      await meta.put('settings', settingsRaw);
    }
  }

  static List<String> _asStringList(Object? source, {required String key}) {
    if (source is! List) {
      throw FormatException('$key يجب أن يكون قائمة.');
    }
    final out = <String>[];
    for (final item in source) {
      if (item is String) {
        out.add(item);
      } else if (item is Map || item is List) {
        out.add(jsonEncode(item));
      } else {
        throw FormatException('$key يحتوي عنصراً غير مدعوم.');
      }
    }
    return out;
  }
}
