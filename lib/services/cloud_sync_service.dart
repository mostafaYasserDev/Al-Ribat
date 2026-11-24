import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'backup_export_service.dart';

part 'cloud_sync/firebase_access.dart';
part 'cloud_sync/session.dart';
part 'cloud_sync/backup_transfer.dart';

/// واجهة موحّدة لخدمات المزامنة السحابية.
class CloudSyncService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const notConfiguredMessage = 'خدمة Firebase غير مهيأة على هذا الجهاز.';

  static bool get isFirebaseAvailable => _firebaseAvailable();
  static FirebaseAuth? get _auth => _authInstance();
  static FirebaseFirestore? get _firestore => _firestoreInstance();
  static User? get currentUser => _auth?.currentUser;

  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream<User?>.empty();

  static Future<UserCredential?> signInWithGoogle() => _signIn(_googleSignIn);
  static Future<void> signOut() => _signOut(_googleSignIn);
  static Future<void> uploadBackup() => _uploadBackup();
  static Future<void> downloadBackup() => _downloadBackup();
}
