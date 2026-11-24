part of '../cloud_sync_service.dart';

bool _firebaseAvailable() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

FirebaseAuth? _authInstance() {
  if (!_firebaseAvailable()) return null;
  try {
    return FirebaseAuth.instance;
  } catch (_) {
    return null;
  }
}

FirebaseFirestore? _firestoreInstance() {
  if (!_firebaseAvailable()) return null;
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
}
