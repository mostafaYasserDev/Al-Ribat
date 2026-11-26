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
  int _index = 2;

  static const _screens = [
    ProjectsScreen(),
    FocusSessionsScreen(),
    HomeScreen(),
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
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_index != 1) const FocusMiniPlayer(),
          _FloatingNotchedNavBar(
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

class _FloatingNotchedNavBar extends StatelessWidget {
  const _FloatingNotchedNavBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
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
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'اليوم',
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
    final dockColor = isDark ? const Color(0xFF10192B) : Colors.white;
    final borderColor =
        colorScheme.onSurface.withValues(alpha: isDark ? 0.1 : 0.07);
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.52);
    final isHomeSelected = selectedIndex == 2;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SizedBox(
          height: 78,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Floating curved notched dock
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 62,
                child: CustomPaint(
                  painter: _NotchedDockPainter(
                    fillColor: dockColor,
                    borderColor: borderColor,
                    shadowColor: Colors.black.withValues(
                      alpha: isDark ? 0.42 : 0.10,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SideNavTab(
                          item: _items[0],
                          selected: selectedIndex == 0,
                          activeColor: colorScheme.primary,
                          inactiveColor: inactiveColor,
                          onTap: () => onSelect(0),
                        ),
                      ),
                      Expanded(
                        child: _SideNavTab(
                          item: _items[1],
                          selected: selectedIndex == 1,
                          activeColor: colorScheme.primary,
                          inactiveColor: inactiveColor,
                          onTap: () => onSelect(1),
                        ),
                      ),
                      const SizedBox(width: 74),
                      Expanded(
                        child: _SideNavTab(
                          item: _items[3],
                          selected: selectedIndex == 3,
                          activeColor: colorScheme.primary,
                          inactiveColor: inactiveColor,
                          onTap: () => onSelect(3),
                        ),
                      ),
                      Expanded(
                        child: _SideNavTab(
                          item: _items[4],
                          selected: selectedIndex == 4,
                          activeColor: colorScheme.primary,
                          inactiveColor: inactiveColor,
                          onTap: () => onSelect(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Elevated Center Home Orb ("اليوم")
              Positioned(
                top: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isHomeSelected ? 1.06 : 0.96,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isHomeSelected
                                ? LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      Color.lerp(
                                            colorScheme.primary,
                                            Colors.teal,
                                            0.35,
                                          ) ??
                                          colorScheme.primary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isHomeSelected
                                ? null
                                : (isDark
                                    ? const Color(0xFF1A2842)
                                    : const Color(0xFFEAF0ED)),
                            boxShadow: [
                              BoxShadow(
                                color: (isHomeSelected
                                        ? colorScheme.primary
                                        : Colors.black)
                                    .withValues(
                                  alpha: isHomeSelected ? 0.36 : 0.12,
                                ),
                                blurRadius: isHomeSelected ? 16 : 8,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            isHomeSelected
                                ? _items[2].selectedIcon
                                : _items[2].icon,
                            size: 26,
                            color: isHomeSelected
                                ? Colors.white
                                : colorScheme.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[2].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isHomeSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isHomeSelected
                              ? colorScheme.primary
                              : inactiveColor,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavTab extends StatelessWidget {
  const _SideNavTab({
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
            scale: selected ? 1.14 : 1.0,
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
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotchedDockPainter extends CustomPainter {
  const _NotchedDockPainter({
    required this.fillColor,
    required this.borderColor,
    required this.shadowColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const r = 26.0;
    const notchHalf = 42.0;
    const notchDepth = 26.0;

    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(cx - notchHalf - 10, 0)
      ..cubicTo(
        cx - notchHalf + 4,
        0,
        cx - 32,
        notchDepth,
        cx,
        notchDepth,
      )
      ..cubicTo(
        cx + 32,
        notchDepth,
        cx + notchHalf - 4,
        0,
        cx + notchHalf + 10,
        0,
      )
      ..lineTo(w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();

    canvas.drawShadow(path, shadowColor, 14, false);
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(_NotchedDockPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.shadowColor != shadowColor;
}
