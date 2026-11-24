import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../application/providers.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../../features/focus/presentation/widgets/focus_mini_player.dart';
import '../focus/focus_sessions_screen.dart';
import '../history/reflection_history_screen.dart';
import '../home/home_screen.dart';
import '../projects/projects_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/manual_location_dialog.dart';

part 'app_shell_location_dialog.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ProjectsScreen(),
    FocusSessionsScreen(),
    ReflectionHistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _maybeAskLocationMode();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _maybeAskLocationMode() async {
    if (!mounted) return;
    await _showLocationModeDialog(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_index != 2) const FocusMiniPlayer(),
          NavigationBar(
            selectedIndex: _index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'اليوم',
              ),
              NavigationDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder_rounded),
                label: 'المشاريع',
              ),
              NavigationDestination(
                icon: Icon(Icons.center_focus_strong_outlined),
                selectedIcon: Icon(Icons.center_focus_strong_rounded),
                label: 'التركيز',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'التأملات',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'الإعدادات',
              ),
            ],
            onDestinationSelected: (value) => setState(() => _index = value),
          ),
        ],
      ),
    );
  }
}
