import 'dart:convert';
import 'dart:io';

import 'package:al_ribat/core/errors/error_reporter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

part 'backup/backup_json.dart';
part 'backup/backup_export.dart';
part 'backup/backup_import.dart';
part 'backup/backup_restore.dart';
part 'backup/backup_restore_v1.dart';
part 'backup/backup_restore_v1_tasks.dart';
part 'backup/backup_restore_v1_habits.dart';
part 'backup/backup_restore_v2.dart';
part 'backup/backup_restore_helpers.dart';

enum BackupRestoreMode { replace, merge }

class BackupExportService {
  static Future<String> buildJsonString() => _buildBackupJson();

  static Future<bool> exportInteractive() => _exportBackupInteractive();

  static Future<bool> importInteractive({
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) =>
      _importBackupInteractive(mode: mode);

  static Future<void> restoreFromJsonString(
    String raw, {
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) =>
      _restoreBackupFromJson(raw, mode: mode);
}
