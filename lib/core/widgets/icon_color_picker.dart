import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/core/theme/app_icons.dart';

/// Shared Telegram x Apple color & searchable icon selector used by both
/// AddActivitySheet and NewProjectDialog.
class IconColorPickerWidget extends StatelessWidget {
  const IconColorPickerWidget({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.colors,
    required this.quickIcons,
    required this.onIconSelected,
    required this.onColorSelected,
    this.fallbackColor,
  });

  final String? selectedIcon;
  final String? selectedColor;
  final List<String> colors;
  final List<String> quickIcons;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<String> onColorSelected;
  final Color? fallbackColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = AppIcons.parseColor(selectedColor) ??
        fallbackColor ??
        colorScheme.primary;
    final selectedEntry = AppIcons.entryFor(selectedIcon);

    // Ensure selectedIcon is visible in the quick row if it's outside quickIcons
    final displayIcons = <String>[
      if (selectedIcon != null &&
          selectedIcon!.isNotEmpty &&
          !quickIcons.contains(selectedIcon))
        selectedIcon!,
      ...quickIcons,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Colors row
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final hex = colors[idx];
              final color = AppIcons.parseColor(hex) ?? colorScheme.primary;
              final isSel = selectedColor == hex;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onColorSelected(hex);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSel
                        ? Border.all(
                            color: colorScheme.onSurface,
                            width: 2.5,
                          )
                        : null,
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.38),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSel
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Selected icon label + Search All button
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                AppIcons.getIconData(selectedIcon),
                size: 17,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedEntry?.labelAr ?? 'اختر أيقونة',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                HapticFeedback.selectionClick();
                final picked = await showIconSearchSheet(
                  context,
                  initialIcon: selectedIcon,
                  activeColor: activeColor,
                );
                if (picked != null) onIconSelected(picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_rounded, size: 15, color: activeColor),
                    const SizedBox(width: 4),
                    Text(
                      'بحث (${AppIcons.catalog.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Quick icons wrap
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayIcons.map((iconKey) {
            final isSel = selectedIcon == iconKey;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onIconSelected(iconKey);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSel
                      ? activeColor
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AppIcons.getIconData(iconKey),
                  size: 20,
                  color: isSel
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Opens a searchable Apple-style modal with all deduplicated icons in [AppIcons].
Future<String?> showIconSearchSheet(
  BuildContext context, {
  String? initialIcon,
  required Color activeColor,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق',
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => _IconSearchDialog(
      initialIcon: initialIcon,
      activeColor: activeColor,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.93, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _IconSearchDialog extends StatefulWidget {
  const _IconSearchDialog({
    required this.initialIcon,
    required this.activeColor,
  });

  final String? initialIcon;
  final Color activeColor;

  @override
  State<_IconSearchDialog> createState() => _IconSearchDialogState();
}

class _IconSearchDialogState extends State<_IconSearchDialog> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = '';

  static const _categories = [
    '',
    'العبادات',
    'العلم والعمل',
    'الصحة والرياضة',
    'الحياة والعادات',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardBg = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final results = AppIcons.search(
      _searchCtrl.text,
      category: _selectedCategory.isEmpty ? null : _selectedCategory,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 540),
            child: Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              elevation: 18,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'اختيار أيقونة (${results.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم الأيقونة (قرآن، برمجة، مشي...)',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSel = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat.isEmpty ? 'الكل' : cat,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSel
                                  ? Colors.white
                                  : colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                            ),
                          ),
                          selected: isSel,
                          selectedColor: widget.activeColor,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: results.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد أيقونة مطابقة لبحثك',
                              style: TextStyle(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.92,
                            ),
                            itemCount: results.length,
                            itemBuilder: (context, idx) {
                              final entry = results[idx];
                              final isSel = entry.key == widget.initialIcon;
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(context, entry.key);
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? widget.activeColor
                                            .withValues(alpha: 0.16)
                                        : colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.38),
                                    borderRadius: BorderRadius.circular(14),
                                    border: isSel
                                        ? Border.all(
                                            color: widget.activeColor,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        entry.icon,
                                        size: 24,
                                        color: isSel
                                            ? widget.activeColor
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.labelAr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSel
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSel
                                              ? widget.activeColor
                                              : colorScheme.onSurface
                                                  .withValues(alpha: 0.72),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
