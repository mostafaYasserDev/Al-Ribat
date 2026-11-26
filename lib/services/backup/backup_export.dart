part of '../backup_export_service.dart';

Future<bool> _exportBackupInteractive() async {
  final json = await BackupExportService.buildJsonString();
  final name = 'al_ribat_backup_${DateTime.now().millisecondsSinceEpoch}.json';

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$name';
      final file = File(path);
      await file.writeAsString(json, flush: true);
      await Share.shareXFiles([XFile(path)], subject: name);
      return true;
    } catch (e, st) {
      reportError('BackupExportService', e, st);
    }
  }

  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'حفظ النسخة الاحتياطية',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (path == null) return false;
    final p = path.toLowerCase().endsWith('.json') ? path : '$path.json';
    await File(p).writeAsString(json, flush: true);
    return true;
  } catch (e, st) {
    reportError('BackupExportService', e, st);
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Share.share(json, subject: name);
      return true;
    }
    rethrow;
  }
}
