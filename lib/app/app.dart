import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/entities/app_settings.dart';
import '../core/theme/app_theme.dart';
import '../features/ai_assistant/presentation/widgets/ai_download_floating_pill.dart';
import '../presentation/shell/app_shell.dart';
import '../presentation/widgets/app_lock_wrapper.dart';

class AlRibatApp extends ConsumerWidget {
  const AlRibatApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    final mode = switch (settings.themeMode) {
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.system => ThemeMode.system,
    };

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'الرباط',
      locale: const Locale('ar'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            if (child != null) child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AiDownloadFloatingPill(navigatorKey: navigatorKey),
            ),
          ],
        ),
      ),
      home: const AppLockWrapper(
        child: WithForegroundTask(
          child: AppShell(),
        ),
      ),
    );
  }
}
