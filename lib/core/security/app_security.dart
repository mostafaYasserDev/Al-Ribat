import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppSecurity {
  static const String _pinHashKey = 'app_pin_hash';
  static const String _legacyPinKey = 'app_pin';
  static const String _salt = 'al_ribat_secure_pin_salt_2026';

  static String hashPin(String pin) {
    final bytes = utf8.encode('$_salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool hasPinSet() {
    final box = Hive.box<String>('meta_box');
    final hash = box.get(_pinHashKey);
    if (hash != null && hash.isNotEmpty) return true;
    final legacy = box.get(_legacyPinKey);
    return legacy != null && legacy.isNotEmpty;
  }

  static bool verifyPin(String enteredPin) {
    final box = Hive.box<String>('meta_box');
    final hash = box.get(_pinHashKey);
    if (hash != null && hash.isNotEmpty) {
      return hash == hashPin(enteredPin);
    }
    // Check legacy migration
    final legacy = box.get(_legacyPinKey);
    if (legacy != null && legacy.isNotEmpty) {
      if (legacy == enteredPin) {
        // Automatically migrate to hash and delete plaintext
        box.put(_pinHashKey, hashPin(enteredPin));
        box.delete(_legacyPinKey);
        return true;
      }
    }
    return false;
  }

  static Future<void> setPin(String pin) async {
    final box = Hive.box<String>('meta_box');
    final hashed = hashPin(pin);
    await box.put(_pinHashKey, hashed);
    await box.delete(_legacyPinKey);
  }

  static Future<void> removePin() async {
    final box = Hive.box<String>('meta_box');
    await box.delete(_pinHashKey);
    await box.delete(_legacyPinKey);
  }
}
