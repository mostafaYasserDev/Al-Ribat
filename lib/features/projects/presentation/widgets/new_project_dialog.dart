import 'package:flutter/material.dart';

import 'package:al_ribat/core/theme/app_icons.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key, required this.onCreate});

  final Future<void> Function({
    required String projectName,
    String? description,
    String? iconName,
    String? colorHex,
  }) onCreate;

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedIcon = 'folder_special';
  String _selectedColor = '#00897B';
  bool _loading = false;

  static const _availableIcons = [
    'folder_special',
    'book',
    'mosque',
    'menu_book',
    'laptop',
    'rocket_launch',
    'fitness_center',
    'star',
    'lightbulb',
    'flag',
  ];

  static const _availableColors = [
    '#00897B', // Teal
    '#1E88E5', // Blue
    '#5E35B1', // Deep Purple
    '#E65100', // Orange
    '#D81B60', // Pink
    '#43A047', // Green
    '#3949AB', // Indigo
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    await widget.onCreate(
      projectName: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      iconName: _selectedIcon,
      colorHex: _selectedColor,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor =
        AppIcons.parseColor(_selectedColor) ?? colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إنشاء مشروع جديد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم المشروع *',
                hintText: 'مثال: بناء تطبيق، ختم القرآن...',
                prefixIcon: Icon(Icons.folder_special_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'وصف المشروع (اختياري)',
                hintText: 'مثال: خطة متكاملة لتحقيق الهدف...',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Text('اختر أيقونة المشروع', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableIcons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final iconName = _availableIcons[i];
                  final isSelected = iconName == _selectedIcon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = iconName),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.2)
                            : colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? activeColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(AppIcons.getIconData(iconName),
                          size: 20,
                          color: isSelected
                              ? activeColor
                              : colorScheme.onSurfaceVariant),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('اختر لون المشروع', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final hex = _availableColors[i];
                  final color = AppIcons.parseColor(hex) ?? Colors.teal;
                  final isSelected = hex == _selectedColor;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = hex),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 6)
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('إنشاء المشروع'),
            ),
          ],
        ),
      ),
    );
  }
}
