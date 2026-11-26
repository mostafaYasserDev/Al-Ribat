part of '../backup_export_service.dart';

Future<bool> _importBackupInteractive() async {
  final picked = await FilePicker.platform.pickFiles(
    dialogTitle: 'اختر ملف النسخة الاحتياطية',
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) {
    return false;
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
  await BackupExportService.restoreFromJsonString(raw);
  return true;
}
