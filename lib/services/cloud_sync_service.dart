import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'backup_export_service.dart';

class CloudSyncService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static Future<void> uploadBackup() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولًا لمزامنة البيانات.');
    }

    final json = await BackupExportService.buildJsonString();
    final data = jsonDecode(json) as Map<String, dynamic>;

    await _firestore.collection('users').doc(user.uid).set({
      'backup': data,
      'updatedAt': FieldValue.serverTimestamp(),
      'email': user.email,
      'displayName': user.displayName,
    });
  }

  static Future<void> downloadBackup() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولًا لاستعادة البيانات.');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final backup = doc.data()?['backup'];
    if (backup == null) {
      throw Exception('لا توجد نسخة سحابية محفوظة لهذا الحساب.');
    }

    final json = const JsonEncoder().convert(backup);
    await BackupExportService.restoreFromJsonString(json);
  }
}
