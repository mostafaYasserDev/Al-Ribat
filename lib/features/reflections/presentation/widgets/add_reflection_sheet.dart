import 'package:flutter/material.dart';

import 'package:al_ribat/core/theme/app_moods.dart';

class AddReflectionSheet extends StatefulWidget {
  const AddReflectionSheet({
    super.key,
    required this.onSave,
    this.initialText,
    this.initialMood,
  });

  final Future<void> Function(String text, String? mood) onSave;
  final String? initialText;
  final String? initialMood;

  @override
  State<AddReflectionSheet> createState() => _AddReflectionSheetState();
}

class _AddReflectionSheetState extends State<AddReflectionSheet> {
  late final TextEditingController _controller;
  String? _selectedMood;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _selectedMood = widget.initialMood;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMoodSelected(String? mood) => setState(() => _selectedMood = mood);

  Future<void> _save() async {
    final t = _controller.text.trim();
    if (t.isEmpty && _selectedMood == null) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(t, _selectedMood);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialText != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'تعديل التأمل' : 'تأمل جديد',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'يُحفظ تلقائياً مع التاريخ واليوم والساعة.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
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
                    onSelected: (selected) =>
                        _onMoodSelected(selected ? opt.label : null),
                  );
                }).toList(),
              ),
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
