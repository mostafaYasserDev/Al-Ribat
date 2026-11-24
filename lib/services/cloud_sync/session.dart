part of '../cloud_sync_service.dart';

Future<UserCredential?> _signIn(GoogleSignIn googleSignIn) async {
  final auth = _authInstance();
  if (auth == null) throw Exception(CloudSyncService.notConfiguredMessage);

  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) return null;

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return auth.signInWithCredential(credential);
}

Future<void> _signOut(GoogleSignIn googleSignIn) async {
  await googleSignIn.signOut();
  final auth = _authInstance();
  if (auth != null) {
    await auth.signOut();
  }
}
