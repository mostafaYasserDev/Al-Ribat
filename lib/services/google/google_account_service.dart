import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Centralized Google Sign-In & OAuth2 HTTP client with incremental scopes.
/// Keeps all Google APIs isolated behind one auth abstraction.
abstract final class GoogleAccountService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  static bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static FirebaseAuth? get _auth {
    if (!isFirebaseAvailable) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream<User?>.empty();

  static User? get currentFirebaseUser => _auth?.currentUser;
  static GoogleSignInAccount? get currentGoogleUser =>
      _googleSignIn.currentUser;

  /// Signs in with minimal scopes (`email`, `profile`). Returns `null` if the
  /// user cancelled the sign-in flow.
  static Future<UserCredential?> signIn() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final auth = _auth;
    if (auth == null) {
      throw Exception('خدمة Firebase غير مهيأة على هذا الجهاز.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return auth.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final auth = _auth;
    if (auth != null) {
      await auth.signOut();
    }
  }

  /// Ensures the user is signed in and has granted [scopes] incrementally.
  static Future<Map<String, String>> ensureAuthorizedHeaders(
    List<String> scopes,
  ) async {
    var user = _googleSignIn.currentUser;
    user ??= await _googleSignIn.signInSilently();
    user ??= await _googleSignIn.signIn();
    if (user == null) {
      throw Exception('تم إلغاء تسجيل الدخول بحساب Google.');
    }

    if (scopes.isNotEmpty) {
      final granted = await _googleSignIn.requestScopes(scopes);
      if (!granted) {
        throw Exception('لم يتم منح الصلاحية المطلوبة من Google.');
      }
    }

    return user.authHeaders;
  }

  /// Executes an authenticated HTTP request with automatic 401 token refresh.
  static Future<({int statusCode, String body})> authorizedRequest({
    required String method,
    required Uri uri,
    required List<String> scopes,
    Map<String, String>? extraHeaders,
    List<int>? bodyBytes,
  }) async {
    var headers = await ensureAuthorizedHeaders(scopes);
    var result = await _sendHttp(
      method: method,
      uri: uri,
      headers: {...headers, ...?extraHeaders},
      bodyBytes: bodyBytes,
    );

    if (result.statusCode == 401) {
      final user = _googleSignIn.currentUser;
      if (user != null) {
        await user.clearAuthCache();
        headers = await user.authHeaders;
        result = await _sendHttp(
          method: method,
          uri: uri,
          headers: {...headers, ...?extraHeaders},
          bodyBytes: bodyBytes,
        );
      }
    }
    return result;
  }

  static Future<({int statusCode, String body})> _sendHttp({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    List<int>? bodyBytes,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.openUrl(method, uri);
      headers.forEach(req.headers.set);
      if (bodyBytes != null) {
        req.contentLength = bodyBytes.length;
        req.add(bodyBytes);
      }
      final resp = await req.close().timeout(const Duration(seconds: 25));
      final body = await resp.transform(utf8.decoder).join();
      return (statusCode: resp.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }
}
