import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../application/providers.dart';
import '../../core/errors/error_reporter.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/app_settings.dart';
import '../../features/focus/application/active_focus_notifier.dart';
import '../../features/focus/domain/work_session_item.dart';
import '../../features/focus/presentation/widgets/focus_completion_sheet.dart';
import '../../features/focus/presentation/widgets/focus_mini_player.dart';
import '../focus/focus_sessions_screen.dart';
import '../history/reflection_history_screen.dart';
import '../home/home_screen.dart';
import '../projects/projects_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
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
    ref.listen<WorkSessionItem?>(lastCompletedSessionProvider, (prev, next) {
      if (next != null) {
        FocusCompletionSheet.show(context, next);
        ref.read(lastCompletedSessionProvider.notifier).state = null;
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_index != 2) const FocusMiniPlayer(),
          _TelegramAppleNavBar(
            selectedIndex: _index,
            onSelect: (value) {
              if (value != _index) {
                HapticFeedback.selectionClick();
                setState(() => _index = value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NavTabItem {
  const _NavTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _TelegramAppleNavBar extends StatelessWidget {
  const _TelegramAppleNavBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    _NavTabItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'اليوم',
    ),
    _NavTabItem(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'المشاريع',
    ),
    _NavTabItem(
      icon: Icons.center_focus_strong_outlined,
      selectedIcon: Icons.center_focus_strong_rounded,
      label: 'التركيز',
    ),
    _NavTabItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'التأملات',
    ),
    _NavTabItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'الإعدادات',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final bgColor = isDark ? const Color(0xFF0D1524) : Colors.white;
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final pillColor =
        colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.12);
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.56);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: SizedBox(
            height: 56,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;
                return Stack(
                  children: [
                    AnimatedPositionedDirectional(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      start: selectedIndex * itemWidth + 4,
                      top: 2,
                      bottom: 2,
                      width: itemWidth - 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _items.length; i++)
                          Expanded(
                            child: _NavTabButton(
                              item: _items[i],
                              selected: i == selectedIndex,
                              activeColor: colorScheme.primary,
                              inactiveColor: inactiveColor,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final _NavTabItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.12 : 1.0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                key: ValueKey(selected),
                size: 22,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: Theme.of(context).textTheme.labelSmall?.fontFamily,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
              height: 1.1,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
