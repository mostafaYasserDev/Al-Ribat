part of '../backup_export_service.dart';

Future<void> _putBackupByEntityId(Box<String> box, String jsonStr) async {
  final map = jsonDecode(jsonStr) as Map<String, dynamic>;
  final id = map['id']?.toString();
  if (id == null || id.isEmpty) {
    throw const FormatException('عنصر النسخة الاحتياطية يفتقد حقل id.');
  }
  await box.put(id, jsonStr);
}

List<String> _asBackupStringList(Object? source, {required String key}) {
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
      throw FormatException('$key يحتوي عنصرًا غير مدعوم.');
    }
  }
  return out;
}
