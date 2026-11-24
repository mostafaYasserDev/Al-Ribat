import 'dart:io';

import 'package:al_ribat/core/security/app_security.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('al_ribat_security_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>('meta_box');
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk('meta_box');
    await tempDir.delete(recursive: true);
  });

  test('sets and verifies hashed PIN', () async {
    expect(AppSecurity.hasPinSet(), false);

    await AppSecurity.setPin('1234');
    expect(AppSecurity.hasPinSet(), true);
    expect(AppSecurity.verifyPin('1234'), true);
    expect(AppSecurity.verifyPin('0000'), false);

    // Verify plaintext is not stored
    expect(box.get('app_pin'), isNull);
    expect(box.get('app_pin_hash'), isNotNull);

    await AppSecurity.removePin();
    expect(AppSecurity.hasPinSet(), false);
    expect(AppSecurity.verifyPin('1234'), false);
  });

  test('migrates legacy plaintext PIN to hash on first verification', () async {
    await box.put('app_pin', '5678');
    expect(AppSecurity.hasPinSet(), true);

    // Verify legacy PIN
    final verified = AppSecurity.verifyPin('5678');
    expect(verified, true);

    // Should now be migrated
    expect(box.get('app_pin'), isNull);
    expect(box.get('app_pin_hash'), isNotNull);
    expect(AppSecurity.verifyPin('5678'), true);
  });
}
