import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_moods.dart';

/// Telegram x Apple-style multi-select mood picker bottom sheet.
Future<List<String>?> showMoodPickerSheet(
  BuildContext context, {
  required List<String> initialMoods,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _MoodPickerSheet(initialMoods: initialMoods),
    ),
  );
}

class _MoodPickerSheet extends StatefulWidget {
  const _MoodPickerSheet({required this.initialMoods});

  final List<String> initialMoods;

  @override
  State<_MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<_MoodPickerSheet> {
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
    final sheetBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: sheetBg,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر مشاعرك',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _selected.isEmpty
                              ? 'يمكنك اختيار أكثر من شعور'
                              : 'تم اختيار ${_selected.length} من ${AppMoods.options.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.58),
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
                      child: const Text('مسح'),
                    ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context, _selected.toList());
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('تم'),
                  ),
                ],
              ),
            ),
            Divider(
              height: 0.6,
              thickness: 0.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.18,
                  ),
                  itemCount: AppMoods.options.length,
                  itemBuilder: (context, index) {
                    final opt = AppMoods.options[index];
                    final isSelected = _selected.contains(opt.label);
                    return _MoodGridTile(
                      option: opt,
                      isSelected: isSelected,
                      onTap: () => _toggle(opt.label),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodGridTile extends StatefulWidget {
  const _MoodGridTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final MoodOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MoodGridTile> createState() => _MoodGridTileState();
}

class _MoodGridTileState extends State<_MoodGridTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final opt = widget.option;
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? opt.color.withValues(alpha: isDark ? 0.22 : 0.13)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: isDark ? 0.35 : 0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? opt.color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.06),
              width: selected ? 1.5 : 0.7,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: opt.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(opt.icon, color: opt.color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      opt.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12.5,
                        color: selected ? opt.color : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: opt.color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Telegram x Apple-style project picker bottom sheet.
/// Returns `null` if dismissed, or `({String? projectTag})` on selection/clear.
Future<({String? projectTag})?> showProjectPickerSheet(
  BuildContext context, {
  required List<String> projectNames,
  String? currentProjectTag,
}) {
  return showModalBottomSheet<({String? projectTag})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      final sheetBg = theme.cardTheme.color ??
          (isDark ? const Color(0xFF111B2E) : Colors.white);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Material(
            color: sheetBg,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                  child: Text(
                    'ربط الخاطرة بمشروع',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Divider(
                  height: 0.6,
                  thickness: 0.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: projectNames.length +
                        (currentProjectTag != null ? 1 : 0),
                    separatorBuilder: (_, __) => Divider(
                      height: 0.6,
                      thickness: 0.6,
                      indent: 56,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.07),
                    ),
                    itemBuilder: (_, index) {
                      if (currentProjectTag != null &&
                          index == projectNames.length) {
                        return ListTile(
                          leading: Icon(
                            Icons.link_off_rounded,
                            color: theme.colorScheme.error,
                          ),
                          title: Text(
                            'إلغاء الربط بالمشروع',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx, (projectTag: null));
                          },
                        );
                      }

                      final proj = projectNames[index];
                      final tag = 'مشروع: $proj';
                      final isSelected = currentProjectTag == tag;

                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            size: 18,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        title: Text(
                          proj,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(ctx, (projectTag: tag));
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      );
    },
  );
}
