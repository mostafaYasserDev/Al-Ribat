import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_moods.dart';
import '../../../settings/presentation/widgets/settings_action_sheet.dart';
import '../../../settings/presentation/widgets/settings_ui_components.dart';

/// Compact Telegram x Apple-style multi-select mood popover anchored to [anchorKey].
Future<List<String>?> showMoodPickerSheet(
  BuildContext context, {
  required List<String> initialMoods,
  GlobalKey? anchorKey,
}) {
  final screenSize = MediaQuery.sizeOf(context);
  final padding = MediaQuery.paddingOf(context);
  final renderBox = anchorKey?.currentContext?.findRenderObject() as RenderBox?;

  Rect anchorRect;
  if (renderBox != null && renderBox.hasSize) {
    final topLeft = renderBox.localToGlobal(Offset.zero);
    anchorRect = topLeft & renderBox.size;
  } else {
    anchorRect = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height - 72),
      width: 48,
      height: 48,
    );
  }

  const horizontalMargin = 14.0;
  final menuWidth =
      (screenSize.width - horizontalMargin * 2).clamp(280.0, 350.0);
  final spaceAbove = anchorRect.top - padding.top;
  final spaceBelow = screenSize.height - padding.bottom - anchorRect.bottom;
  final showAbove = spaceAbove >= 240 || spaceAbove >= spaceBelow;

  final left = (anchorRect.center.dx - menuWidth / 2).clamp(
    horizontalMargin,
    screenSize.width - menuWidth - horizontalMargin,
  );
  final double? bottom =
      showAbove ? (screenSize.height - anchorRect.top + 8) : null;
  final double? top = showAbove ? null : (anchorRect.bottom + 8);
  final relX =
      ((anchorRect.center.dx - left) / menuWidth * 2 - 1).clamp(-1.0, 1.0);
  final scaleAlignment = Alignment(relX, showAbove ? 1.0 : -1.0);

  return showGeneralDialog<List<String>>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, _, __) => Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            bottom: bottom,
            width: menuWidth,
            child: _MoodPickerCard(initialMoods: initialMoods),
          ),
        ],
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final scaleAnim = Tween<double>(begin: 0.36, end: 1.0).animate(
        CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        ),
      );
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(ctx).pop(),
              child: FadeTransition(
                opacity: curved,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ),
          FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: scaleAnim,
              alignment: scaleAlignment,
              child: child,
            ),
          ),
        ],
      );
    },
  );
}

class _MoodPickerCard extends StatefulWidget {
  const _MoodPickerCard({required this.initialMoods});

  final List<String> initialMoods;

  @override
  State<_MoodPickerCard> createState() => _MoodPickerCardState();
}

class _MoodPickerCardState extends State<_MoodPickerCard> {
  late final Set<String> _selected = Set<String>.from(widget.initialMoods);

  void _toggle(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(label)) {
        _selected.remove(label);
      } else {
        _selected.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF162238).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.97);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.onSurface
                .withValues(alpha: isDark ? 0.12 : 0.08),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر مشاعرك',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        Text(
                          _selected.isEmpty
                              ? 'اختر شعوراً أو أكثر'
                              : 'تم اختيار ${_selected.length} من ${AppMoods.options.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.56),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected.clear());
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('مسح', style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(width: 4),
                  PressableScale(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, _selected.toList());
                    },
                    child: Material(
                      color: theme.colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context, _selected.toList());
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          child: Text(
                            'تم',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 0.6,
              thickness: 0.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 7,
                  crossAxisSpacing: 7,
                  childAspectRatio: 2.25,
                ),
                itemCount: AppMoods.options.length,
                itemBuilder: (context, index) {
                  final opt = AppMoods.options[index];
                  final isSelected = _selected.contains(opt.label);
                  return _CompactMoodTile(
                    option: opt,
                    isSelected: isSelected,
                    onTap: () => _toggle(opt.label),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMoodTile extends StatelessWidget {
  const _CompactMoodTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final MoodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PressableScale(
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? option.color.withValues(alpha: isDark ? 0.24 : 0.14)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: isDark ? 0.28 : 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? option.color.withValues(alpha: 0.7)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, color: option.color, size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11.5,
                    color: isSelected ? option.color : null,
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

/// Telegram x Apple-style anchored project picker popover.
/// Returns `null` if dismissed, or `({String? projectTag})` on selection/clear.
Future<({String? projectTag})?> showProjectPickerSheet(
  BuildContext context, {
  required List<String> projectNames,
  String? currentProjectTag,
  GlobalKey? anchorKey,
}) async {
  final options = <AnchoredMenuOption<({String? projectTag})>>[
    for (final proj in projectNames)
      AnchoredMenuOption(
        value: (projectTag: 'مشروع: $proj'),
        title: proj,
        subtitle: currentProjectTag == 'مشروع: $proj' ? 'مرتبط حالياً' : null,
        icon: currentProjectTag == 'مشروع: $proj'
            ? Icons.check_circle_rounded
            : Icons.folder_rounded,
        color: currentProjectTag == 'مشروع: $proj'
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.secondary,
      ),
    if (currentProjectTag != null)
      const AnchoredMenuOption(
        value: (projectTag: null),
        title: 'إلغاء الربط بالمشروع',
        icon: Icons.link_off_rounded,
        isDestructive: true,
      ),
  ];

  final key = anchorKey ?? GlobalKey();
  return showAnchoredSettingsMenu<({String? projectTag})>(
    context: context,
    anchorKey: key,
    title: 'ربط الخاطرة بمشروع',
    options: options,
  );
}
