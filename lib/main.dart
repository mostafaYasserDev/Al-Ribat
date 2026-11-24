import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/app_startup.dart';
import 'core/bootstrap.dart';
import 'core/errors/error_reporter.dart';
import 'services/focus_foreground_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  FlutterForegroundTask.initCommunicationPort();
  await bootstrap();
  await ensureForegroundTaskPluginInitialized();
  runApp(const ProviderScope(child: AlRibatApp()));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (error, stack) {
    AppStartup.recordFirebaseFailure(error);
    reportError('Firebase.initializeApp', error, stack);
  }
}
