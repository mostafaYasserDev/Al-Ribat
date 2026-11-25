import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:al_ribat/core/theme/app_icons.dart';
import 'package:al_ribat/features/reflections/presentation/widgets/apple_morph_route.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key, required this.onCreate});

  final Future<void> Function({
    required String projectName,
    String? description,
    String? iconName,
    String? colorHex,
  }) onCreate;

  /// Opens [NewProjectDialog] with an Apple spatial morph from [sourceContext].
  static Future<void> open(
    BuildContext context, {
    required Future<void> Function({
      required String projectName,
      String? description,
      String? iconName,
      String? colorHex,
    }) onCreate,
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 18,
  }) {
    final sourceRect = captureWidgetRect(sourceContext);
    return Navigator.of(context).push<void>(
      AppleMorphRoute<void>(
        sourceRect: sourceRect,
        sourceColor: sourceColor,
        sourceRadius: sourceRadius,
        builder: (_) => NewProjectDialog(onCreate: onCreate),
      ),
    );
  }

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedIcon = 'folder_special';
  String _selectedColor = '#1F6F4A';
  bool _loading = false;

  static const _availableIcons = [
    'folder_special',
    'mosque',
    'menu_book',
    'book',
    'code',
    'rocket_launch',
    'lightbulb',
    'star',
    'flag',
    'fitness_center',
  ];

  static const _availableColors = [
    '#1F6F4A',
    '#007AFF',
    '#7C3AED',
    '#FF9500',
    '#F43F5E',
    '#34C759',
    '#00897B',
    '#5C6BC0',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _loading) return;
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      await widget.onCreate(
        projectName: name,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        iconName: _selectedIcon,
        colorHex: _selectedColor,
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final dividerColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final activeColor =
        AppIcons.parseColor(_selectedColor) ?? colorScheme.primary;
    final canSubmit = _nameCtrl.text.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'إلغاء',
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'مشروع جديد',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: FilledButton(
                onPressed: canSubmit && !_loading ? _submit : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  minimumSize: const Size(0, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'إنشاء',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.6),
            child: Container(height: 0.6, color: dividerColor),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dividerColor, width: 0.7),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            AppIcons.getIconData(_selectedIcon),
                            color: activeColor,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            autofocus: true,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'اسم المشروع (مثال: ختم القرآن)…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0.6, thickness: 0.6, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'وصف المشروع أو هدفه العام (اختياري)',
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(6, 18, 6, 8),
              child: Text(
                'الأيقونة واللون',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.56),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dividerColor, width: 0.7),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableIcons.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final iconName = _availableIcons[i];
                        final isSelected = iconName == _selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedIcon = iconName);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 46,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor.withValues(alpha: 0.16)
                                  : colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? activeColor
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              AppIcons.getIconData(iconName),
                              size: 21,
                              color: isSelected
                                  ? activeColor
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        final hex = _availableColors[i];
                        final color =
                            AppIcons.parseColor(hex) ?? colorScheme.primary;
                        final isSelected = hex == _selectedColor;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = hex);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? colorScheme.onSurface
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
