part of '../cloud_sync_service.dart';

Future<User> _signedInUser() {
  final auth = _authInstance();
  if (auth == null) throw Exception(CloudSyncService.notConfiguredMessage);
  final user = auth.currentUser;
  if (user == null) {
    throw Exception('يجب تسجيل الدخول أولًا لمزامنة البيانات.');
  }
  return Future.value(user);
}

Future<void> _uploadBackup() async {
  await _signedInUser();
  await GoogleDriveBackupService.uploadBackup();
}

Future<void> _downloadBackup({
  BackupRestoreMode mode = BackupRestoreMode.replace,
}) async {
  final user = await _signedInUser();
  final restoredFromDrive =
      await GoogleDriveBackupService.downloadBackup(mode: mode);
  if (restoredFromDrive) return;

  // Read-only legacy Firestore fallback for older backups (planned for removal).
  final firestore = CloudSyncService._firestore;
  if (firestore != null) {
    final doc = await firestore.collection('users').doc(user.uid).get();
    final backup = doc.data()?['backup'];
    if (backup != null) {
      final json = const JsonEncoder().convert(backup);
      await BackupExportService.restoreFromJsonString(json, mode: mode);
      return;
    }
  }

  throw Exception('لا توجد نسخة سحابية محفوظة لهذا الحساب.');
}
