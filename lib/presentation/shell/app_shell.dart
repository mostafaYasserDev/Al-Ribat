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
import '../../features/activities/presentation/widgets/add_activity_sheet.dart';
import '../../features/focus/application/active_focus_notifier.dart';
import '../../features/focus/domain/work_session_item.dart';
import '../../features/focus/presentation/widgets/focus_completion_sheet.dart';
import '../../features/focus/presentation/widgets/focus_mini_player.dart';
import '../../features/projects/presentation/widgets/anchored_popover.dart';
import '../../features/reflections/presentation/reflection_editor_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../services/motivation_quotes.dart';
import '../focus/focus_sessions_screen.dart';
import '../history/reflection_history_screen.dart';
import '../home/home_screen.dart';
import '../projects/projects_screen.dart';
import '../widgets/manual_location_dialog.dart';

part 'app_shell_location_dialog.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
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

  void _openQuickAddMenu(BuildContext anchorCtx) {
    HapticFeedback.lightImpact();
    final dividerColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    final hostContext = context;

    showAnchoredPopover<void>(
      anchorCtx,
      width: 248,
      preferAbove: true,
      anchorRadius: 28,
      builder: (popCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopoverActionRow(
            icon: Icons.add_task_rounded,
            color: const Color(0xFF1F6F4A),
            label: 'نشاط جديد',
            onTap: () {
              Navigator.pop(popCtx);
              AddActivitySheet.open(
                hostContext,
                sourceContext: anchorCtx,
                sourceColor: Theme.of(hostContext).colorScheme.primary,
                sourceRadius: 28,
                onSave: (activity) async {
                  await ref
                      .read(activitiesProvider.notifier)
                      .addActivity(activity);
                  lightSuccessHaptic();
                  if (hostContext.mounted) {
                    appSnack(
                      hostContext,
                      'أُضِيف النشاط — ${MotivationQuotes.randomLine()}',
                    );
                  }
                  return true;
                },
              );
            },
          ),
          Divider(height: 0.6, thickness: 0.6, indent: 52, color: dividerColor),
          PopoverActionRow(
            icon: Icons.center_focus_strong_rounded,
            color: const Color(0xFF007AFF),
            label: 'بدء جلسة تركيز',
            onTap: () {
              Navigator.pop(popCtx);
              ref.read(shellTabProvider.notifier).state = 2;
            },
          ),
          Divider(height: 0.6, thickness: 0.6, indent: 52, color: dividerColor),
          PopoverActionRow(
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF7C3AED),
            label: 'تأمل جديد',
            onTap: () {
              Navigator.pop(popCtx);
              ReflectionEditorScreen.open(
                hostContext,
                sourceContext: anchorCtx,
                sourceColor: const Color(0xFF7C3AED).withValues(alpha: 0.16),
                sourceRadius: 28,
              );
            },
          ),
          Divider(height: 0.6, thickness: 0.6, indent: 52, color: dividerColor),
          PopoverActionRow(
            icon: Icons.create_new_folder_rounded,
            color: const Color(0xFFFF9500),
            label: 'مشروع جديد',
            onTap: () {
              Navigator.pop(popCtx);
              NewProjectDialog.open(
                hostContext,
                sourceContext: anchorCtx,
                sourceColor: const Color(0xFFFF9500).withValues(alpha: 0.16),
                sourceRadius: 28,
                onCreate: ({
                  required String projectName,
                  String? description,
                  String? iconName,
                  String? colorHex,
                }) async {
                  await ProjectGroupsService.saveProjectInfo(
                    projectName,
                    description: description,
                    iconName: iconName,
                    colorHex: colorHex,
                  );
                  ref.read(shellTabProvider.notifier).state = 1;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(shellTabProvider);

    ref.listen<WorkSessionItem?>(lastCompletedSessionProvider, (prev, next) {
      if (next != null) {
        FocusCompletionSheet.show(context, next);
        ref.read(lastCompletedSessionProvider.notifier).state = null;
      }
    });

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (index != 2) const FocusMiniPlayer(),
          _CurvedNotchedNavBar(
            selectedIndex: index,
            onSelect: (value) {
              if (value != index) {
                HapticFeedback.selectionClick();
                ref.read(shellTabProvider.notifier).state = value;
              }
            },
            onCenterAddTap: _openQuickAddMenu,
          ),
        ],
      ),
    );
  }
}

class _NavTabItem {
  const _NavTabItem({
    required this.tabIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.activeColor,
  });

  final int tabIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color activeColor;
}

class _CurvedNotchedNavBar extends StatefulWidget {
  const _CurvedNotchedNavBar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onCenterAddTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final void Function(BuildContext anchorContext) onCenterAddTap;

  @override
  State<_CurvedNotchedNavBar> createState() => _CurvedNotchedNavBarState();
}

class _CurvedNotchedNavBarState extends State<_CurvedNotchedNavBar> {
  final _centerBtnKey = GlobalKey();
  bool _centerPressed = false;

  static const _rightTabs = [
    _NavTabItem(
      tabIndex: 0,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'اليوم',
      activeColor: Color(0xFF1F6F4A),
    ),
    _NavTabItem(
      tabIndex: 1,
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'المشاريع',
      activeColor: Color(0xFF007AFF),
    ),
  ];

  static const _leftTabs = [
    _NavTabItem(
      tabIndex: 3,
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      label: 'التأملات',
      activeColor: Color(0xFF7C3AED),
    ),
    _NavTabItem(
      tabIndex: 4,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'الإعدادات',
      activeColor: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final barColor = isDark ? const Color(0xFF10192A) : Colors.white;
    final borderColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final inactiveColor = colorScheme.onSurface.withValues(alpha: 0.52);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 82 + bottomInset,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Curved notched bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 66 + bottomInset,
            child: CustomPaint(
              painter: _NotchedBarPainter(
                color: barColor,
                borderColor: borderColor,
                shadowColor:
                    Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset, top: 6),
                child: Row(
                  children: [
                    for (final item in _rightTabs)
                      Expanded(
                        child: _CurvedNavTabButton(
                          item: item,
                          selected: widget.selectedIndex == item.tabIndex,
                          inactiveColor: inactiveColor,
                          onTap: () => widget.onSelect(item.tabIndex),
                        ),
                      ),
                    const SizedBox(width: 78),
                    for (final item in _leftTabs)
                      Expanded(
                        child: _CurvedNavTabButton(
                          item: item,
                          selected: widget.selectedIndex == item.tabIndex,
                          inactiveColor: inactiveColor,
                          onTap: () => widget.onSelect(item.tabIndex),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Center floating circular (+) button cradled in the notch
          Positioned(
            bottom: 24 + bottomInset,
            child: GestureDetector(
              key: const Key('center_add_button'),
              onTapDown: (_) => setState(() => _centerPressed = true),
              onTapUp: (_) {
                setState(() => _centerPressed = false);
                widget.onCenterAddTap(
                  _centerBtnKey.currentContext ?? context,
                );
              },
              onTapCancel: () => setState(() => _centerPressed = false),
              child: AnimatedScale(
                key: _centerBtnKey,
                scale: _centerPressed ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        Color.lerp(colorScheme.primary, const Color(0xFF007AFF),
                            0.28)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.38),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter({
    required this.color,
    required this.borderColor,
    required this.shadowColor,
  });

  final Color color;
  final Color borderColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    const cornerR = 26.0;
    const notchHalfW = 46.0;
    const notchDepth = 28.0;

    final path = Path()
      ..moveTo(0, cornerR)
      ..quadraticBezierTo(0, 0, cornerR, 0)
      ..lineTo(cx - notchHalfW, 0)
      ..cubicTo(
        cx - notchHalfW * 0.56,
        0,
        cx - notchHalfW * 0.54,
        notchDepth,
        cx,
        notchDepth,
      )
      ..cubicTo(
        cx + notchHalfW * 0.54,
        notchDepth,
        cx + notchHalfW * 0.56,
        0,
        cx + notchHalfW,
        0,
      )
      ..lineTo(w - cornerR, 0)
      ..quadraticBezierTo(w, 0, w, cornerR)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawShadow(path, shadowColor, 10, false);
    canvas.drawPath(path, Paint()..color = color);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(_NotchedBarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}

class _CurvedNavTabButton extends StatelessWidget {
  const _CurvedNavTabButton({
    required this.item,
    required this.selected,
    required this.inactiveColor,
    required this.onTap,
  });

  final _NavTabItem item;
  final bool selected;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? item.activeColor : inactiveColor;
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
                size: 23,
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
              fontSize: 10.5,
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
