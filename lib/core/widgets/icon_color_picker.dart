import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/core/theme/app_icons.dart';

/// Shared Telegram x Apple color & inline searchable icon selector used by both
/// AddActivitySheet and NewProjectDialog without cluttering the screen.
class IconColorPickerWidget extends StatefulWidget {
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
  State<IconColorPickerWidget> createState() => _IconColorPickerWidgetState();
}

class _IconColorPickerWidgetState extends State<IconColorPickerWidget> {
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
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = AppIcons.parseColor(widget.selectedColor) ??
        widget.fallbackColor ??
        colorScheme.primary;
    final selectedEntry = AppIcons.entryFor(widget.selectedIcon);
    final results = AppIcons.search(
      _searchCtrl.text,
      category: _selectedCategory.isEmpty ? null : _selectedCategory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Colors row
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, idx) {
              final hex = widget.colors[idx];
              final color = AppIcons.parseColor(hex) ?? colorScheme.primary;
              final isSel = widget.selectedColor == hex;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onColorSelected(hex);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSel
                        ? Border.all(
                            color: colorScheme.onSurface,
                            width: 2.3,
                          )
                        : null,
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: isSel
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Selected preview + inline search bar
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                AppIcons.getIconData(widget.selectedIcon),
                size: 18,
                color: activeColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: selectedEntry != null
                        ? 'ابحث (الحالية: ${selectedEntry.labelAr})…'
                        : 'ابحث عن أيقونة بالاسم…',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.36),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 17),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Category chips
        SizedBox(
          height: 28,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final cat = _categories[idx];
              final isSel = _selectedCategory == cat;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSel
                        ? activeColor
                        : colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    cat.isEmpty ? 'الكل' : cat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSel
                          ? Colors.white
                          : colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Compact 2-row horizontal scrollable icon strip (does not clutter the screen)
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'لا توجد أيقونة مطابقة',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 102,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: const {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.95,
                ),
                itemCount: results.length,
                itemBuilder: (context, idx) {
                  final entry = results[idx];
                  final isSel = widget.selectedIcon == entry.key;
                  return Tooltip(
                    message: entry.labelAr,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onIconSelected(entry.key);
                      },
                      borderRadius: BorderRadius.circular(13),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        decoration: BoxDecoration(
                          color: isSel
                              ? activeColor
                              : colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          entry.icon,
                          size: 21,
                          color: isSel
                              ? Colors.white
                              : colorScheme.onSurface.withValues(alpha: 0.76),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
