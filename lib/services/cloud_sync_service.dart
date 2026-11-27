import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'backup_export_service.dart';
import 'google/google_account_service.dart';
import 'google/google_drive_backup_service.dart';

part 'cloud_sync/firebase_access.dart';
part 'cloud_sync/session.dart';
part 'cloud_sync/backup_transfer.dart';

/// واجهة موحّدة لخدمات المزامنة السحابية (Google Drive appDataFolder أساساً،
/// مع إبقاء Firestore كخيار قراءة احتياطي مؤقت للنسخ القديمة).
class CloudSyncService {
  static const notConfiguredMessage = 'خدمة Firebase غير مهيأة على هذا الجهاز.';

  static bool get isFirebaseAvailable => _firebaseAvailable();
  static FirebaseAuth? get _auth => _authInstance();
  static FirebaseFirestore? get _firestore => _firestoreInstance();
  static User? get currentUser => _auth?.currentUser;

  static Stream<User?> get authStateChanges =>
      GoogleAccountService.authStateChanges;

  static Future<UserCredential?> signInWithGoogle() => _signIn();
  static Future<void> signOut() => _signOut();
  static Future<void> uploadBackup() => _uploadBackup();
  static Future<void> downloadBackup({
    BackupRestoreMode mode = BackupRestoreMode.replace,
  }) =>
      _downloadBackup(mode: mode);
}
