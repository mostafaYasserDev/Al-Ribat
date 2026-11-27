import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../backup_export_service.dart';
import 'google_account_service.dart';

class DriveBackupMetadata {
  const DriveBackupMetadata({
    required this.id,
    required this.name,
    this.modifiedTime,
    this.sizeBytes,
  });

  final String id;
  final String name;
  final DateTime? modifiedTime;
  final int? sizeBytes;
}

/// Stores and restores `al_ribat_backup.json` inside the user's hidden
/// Google Drive `appDataFolder` (no 1 MiB Firestore limit, private to this app).
abstract final class GoogleDriveBackupService {
  static const _scope = 'https://www.googleapis.com/auth/drive.appdata';
  static const _fileName = 'al_ribat_backup.json';

  static Future<DriveBackupMetadata?> findLatestBackup() async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'spaces': 'appDataFolder',
      'q': "name='$_fileName' and trashed=false",
      'fields': 'files(id,name,modifiedTime,size)',
      'orderBy': 'modifiedTime desc',
      'pageSize': '1',
    });

    final resp = await GoogleAccountService.authorizedRequest(
      method: 'GET',
      uri: uri,
      scopes: const [_scope],
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('تعذر الوصول إلى Google Drive (${resp.statusCode}).');
    }
    return parseDriveFileList(resp.body);
  }

  @visibleForTesting
  static DriveBackupMetadata? parseDriveFileList(String jsonBody) {
    final decoded = jsonDecode(jsonBody);
    if (decoded is! Map) return null;
    final files = decoded['files'];
    if (files is! List || files.isEmpty) return null;
    final first = files.first;
    if (first is! Map) return null;
    final id = first['id']?.toString();
    if (id == null || id.isEmpty) return null;

    return DriveBackupMetadata(
      id: id,
      name: first['name']?.toString() ?? _fileName,
      modifiedTime: DateTime.tryParse(first['modifiedTime']?.toString() ?? ''),
      sizeBytes: int.tryParse(first['size']?.toString() ?? ''),
    );
  }

  static Future<void> uploadBackup() async {
    final json = await BackupExportService.buildJsonString();
    final existing = await findLatestBackup();

    if (existing != null) {
      final uri = Uri.https(
        'www.googleapis.com',
        '/upload/drive/v3/files/${existing.id}',
        {'uploadType': 'media'},
      );
      final resp = await GoogleAccountService.authorizedRequest(
        method: 'PATCH',
        uri: uri,
        scopes: const [_scope],
        extraHeaders: const {'Content-Type': 'application/json; charset=utf-8'},
        bodyBytes: utf8.encode(json),
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception(
            'فشل تحديث النسخة على Google Drive (${resp.statusCode}).');
      }
      return;
    }

    const boundary = 'al_ribat_drive_boundary_2026';
    final multipartBytes = buildMultipartBody(
      boundary: boundary,
      fileName: _fileName,
      jsonContent: json,
    );
    final uri = Uri.https(
      'www.googleapis.com',
      '/upload/drive/v3/files',
      {'uploadType': 'multipart'},
    );
    final resp = await GoogleAccountService.authorizedRequest(
      method: 'POST',
      uri: uri,
      scopes: const [_scope],
      extraHeaders: {
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      bodyBytes: multipartBytes,
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('فشل رفع النسخة إلى Google Drive (${resp.statusCode}).');
    }
  }

  @visibleForTesting
  static List<int> buildMultipartBody({
    required String boundary,
    required String fileName,
    required String jsonContent,
  }) {
    final metadata = jsonEncode({
      'name': fileName,
      'parents': ['appDataFolder'],
    });
    final payload = '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n'
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$jsonContent\r\n'
        '--$boundary--\r\n';
    return utf8.encode(payload);
  }

  /// Downloads and restores the Drive backup. Returns `false` if no Drive
  /// backup exists yet so callers can fall back to legacy Firestore if needed.
  static Future<bool> downloadBackup({
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) async {
    final existing = await findLatestBackup();
    if (existing == null) return false;

    final uri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files/${existing.id}',
      {'alt': 'media'},
    );
    final resp = await GoogleAccountService.authorizedRequest(
      method: 'GET',
      uri: uri,
      scopes: const [_scope],
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
          'تعذر تنزيل النسخة من Google Drive (${resp.statusCode}).');
    }
    await BackupExportService.restoreFromJsonString(resp.body, mode: mode);
    return true;
  }
}
