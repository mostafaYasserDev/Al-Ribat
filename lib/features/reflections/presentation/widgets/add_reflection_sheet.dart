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
  bool _isSaving = false;

  static const _quickPrompts = <({String label, String starter})>[
    (label: 'نعمة اليوم', starter: 'نعمة أشكر الله عليها اليوم: '),
    (label: 'إنجاز أسعدني', starter: 'إنجاز أسعدني اليوم: '),
    (label: 'درس تعلمته', starter: 'درس تعلمته اليوم: '),
    (label: 'نية للغد', starter: 'نية أجددها للغد: '),
  ];

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

  void _applyPrompt(String starter) {
    final current = _controller.text.trim();
    final updated = current.isEmpty ? starter : '$current\n$starter';
    _controller.text = updated;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
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
    final activities = ref.watch(activitiesProvider).valueOrNull ?? const [];
    final projectNames = activities
        .map((a) => a.projectName?.trim() ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
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
                isEditing ? 'تعديل التأمل' : 'تأمل جديد',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'يُحفظ تلقائياً مع الوقت واسم الصلاة الحالية.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              Text('كيف تشعر الآن؟',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: AppMoods.options.map((opt) {
                  final isSelected = _selectedMood == opt.label;
                  return ChoiceChip(
                    avatar: Icon(
                      opt.icon,
                      size: 18,
                      color: isSelected ? null : opt.color,
                    ),
                    label: Text(opt.label),
                    selected: isSelected,
                    onSelected: (selected) => setState(
                      () => _selectedMood = selected ? opt.label : null,
                    ),
                  );
                }).toList(),
              ),
              if (!isEditing) ...[
                const SizedBox(height: 14),
                Text('بداية سريعة (اختياري)',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickPrompts.map((p) {
                    return ActionChip(
                      label:
                          Text(p.label, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _applyPrompt(p.starter),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
              Text('ملاحظاتك أو خواطرك',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 10,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText:
                      'اكتب ما يخطر ببالك… إنجازاتك، مشاعرك، أو شكرك لله.',
                  alignLabelWithHint: true,
                ),
              ),
              if (projectNames.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('ربط بمشروع (اختياري)',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: projectNames.map((proj) {
                      final tag = 'مشروع: $proj';
                      final isSelected = _selectedContextTitle == tag;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.folder_outlined, size: 16),
                          label: Text(proj),
                          selected: isSelected,
                          onSelected: (sel) => setState(
                            () => _selectedContextTitle = sel ? tag : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ في السجل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
