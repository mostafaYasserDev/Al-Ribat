import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/application/providers.dart';
import 'package:al_ribat/core/theme/app_moods.dart';

class AddReflectionSheet extends ConsumerStatefulWidget {
  const AddReflectionSheet({
    super.key,
    required this.onSave,
    this.initialText,
    this.initialMood,
    this.initialContextTitle,
  });

  final Future<void> Function(
      String text, String? mood, String? linkedContextTitle) onSave;
  final String? initialText;
  final String? initialMood;
  final String? initialContextTitle;

  @override
  ConsumerState<AddReflectionSheet> createState() => _AddReflectionSheetState();
}

class _AddReflectionSheetState extends ConsumerState<AddReflectionSheet> {
  late final TextEditingController _controller;
  String? _selectedMood;
  String? _selectedContextTitle;
  bool _showMoodPicker = false;
  bool _showProjectPicker = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _selectedMood = widget.initialMood;
    _selectedContextTitle = widget.initialContextTitle;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _controller.text.trim();
    if (t.isEmpty && _selectedMood == null) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(t, _selectedMood, _selectedContextTitle);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialText != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activities = ref.watch(activitiesProvider).valueOrNull ?? const [];
    final projectNames = activities
        .map((a) => a.projectName?.trim() ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final moodOpt = AppMoods.find(_selectedMood);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'تعديل التأمل' : 'دوّن تأملك أو خاطرتك',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Primary Hero: Writing Field
              TextField(
                controller: _controller,
                autofocus: !isEditing,
                minLines: 5,
                maxLines: 12,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                decoration: InputDecoration(
                  hintText: 'اكتب ما في خاطرك بكل هدوء وصفاء…',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Compact Secondary Optional Chips (Mood & Project)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: Icon(
                      moodOpt?.icon ?? Icons.mood_outlined,
                      size: 17,
                      color: moodOpt?.color ?? colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      _selectedMood != null
                          ? 'الشعور: $_selectedMood'
                          : 'إضافة شعور (اختياري)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => setState(() {
                      _showMoodPicker = !_showMoodPicker;
                      if (_showMoodPicker) _showProjectPicker = false;
                    }),
                  ),
                  if (_selectedMood != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'إزالة الشعور',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _selectedMood = null),
                    ),
                  if (projectNames.isNotEmpty)
                    ActionChip(
                      avatar: Icon(
                        Icons.folder_outlined,
                        size: 17,
                        color: _selectedContextTitle != null
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        _selectedContextTitle ?? 'ربط بمشروع (اختياري)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => setState(() {
                        _showProjectPicker = !_showProjectPicker;
                        if (_showProjectPicker) _showMoodPicker = false;
                      }),
                    ),
                ],
              ),

              // Compact Horizontal Mood Picker (shown only when toggled)
              if (_showMoodPicker) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppMoods.options.map((opt) {
                      final isSelected = _selectedMood == opt.label;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          avatar: Icon(
                            opt.icon,
                            size: 16,
                            color: isSelected ? null : opt.color,
                          ),
                          label: Text(opt.label,
                              style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          visualDensity: VisualDensity.compact,
                          onSelected: (selected) => setState(() {
                            _selectedMood = selected ? opt.label : null;
                            _showMoodPicker = false;
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              // Compact Horizontal Project Picker (shown only when toggled)
              if (_showProjectPicker && projectNames.isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: projectNames.map((proj) {
                      final tag = 'مشروع: $proj';
                      final isSelected = _selectedContextTitle == tag;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.folder_outlined, size: 15),
                          label:
                              Text(proj, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          visualDensity: VisualDensity.compact,
                          onSelected: (sel) => setState(() {
                            _selectedContextTitle = sel ? tag : null;
                            _showProjectPicker = false;
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'حفظ التأمل',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
