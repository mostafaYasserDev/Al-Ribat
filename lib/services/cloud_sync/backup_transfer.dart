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

Future<FirebaseFirestore> _firestoreOrThrow() {
  final firestore = CloudSyncService._firestore;
  if (firestore == null) {
    throw Exception(CloudSyncService.notConfiguredMessage);
  }
  return Future.value(firestore);
}

Future<void> _uploadBackup() async {
  final user = await _signedInUser();
  final firestore = await _firestoreOrThrow();
  final json = await BackupExportService.buildJsonString();
  final data = jsonDecode(json) as Map<String, dynamic>;

  await firestore.collection('users').doc(user.uid).set({
    'backup': data,
    'updatedAt': FieldValue.serverTimestamp(),
    'email': user.email,
    'displayName': user.displayName,
  });
}

Future<void> _downloadBackup() async {
  final user = await _signedInUser();
  final firestore = await _firestoreOrThrow();
  final doc = await firestore.collection('users').doc(user.uid).get();
  final backup = doc.data()?['backup'];
  if (backup == null) {
    throw Exception('لا توجد نسخة سحابية محفوظة لهذا الحساب.');
  }

  final json = const JsonEncoder().convert(backup);
  await BackupExportService.restoreFromJsonString(json);
}
