import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/entities/app_settings.dart';
import '../core/theme/app_theme.dart';
import '../presentation/shell/app_shell.dart';
import '../presentation/widgets/app_lock_wrapper.dart';

class AlRibatApp extends ConsumerWidget {
  const AlRibatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final mode = switch (settings.themeMode) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'الرباط',
      locale: const Locale('ar'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: AppLockWrapper(
          child: WithForegroundTask(
            child: AppShell(),
          ),
        ),
      ),
    );
  }
}
