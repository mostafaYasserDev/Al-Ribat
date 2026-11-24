import 'package:flutter/material.dart';

import 'package:al_ribat/core/theme/app_moods.dart';
import '../../domain/reflection_entry.dart';

class ReflectionCard extends StatefulWidget {
  const ReflectionCard({
    super.key,
    required this.streakCount,
    required this.onSave,
    this.existingEntry,
    this.onEdit,
    this.onViewHistory,
  });

  final int streakCount;
  final Future<void> Function(String text, String? mood) onSave;
  final ReflectionEntry? existingEntry;
  final VoidCallback? onEdit;
  final VoidCallback? onViewHistory;

  @override
  State<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<ReflectionCard> {
  final _controller = TextEditingController();
  String? _selectedMood;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.existingEntry;
    if (entry != null) {
      return _buildSavedCard(context, entry);
    }
    return _buildFormCard(context);
  }

  Widget _buildSavedCard(BuildContext context, ReflectionEntry entry) {
    final primary = Theme.of(context).colorScheme.primary;
    final primaryContainer = Theme.of(context).colorScheme.primaryContainer;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primary.withValues(alpha: 0.3)),
      ),
      color: primaryContainer.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تأملك المسجل لليوم',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                    ),
                  ],
                ),
                if (entry.mood != null)
                  MoodDisplayChip(mood: entry.mood!, dense: true),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              entry.text.isEmpty ? 'لم تُضف ملاحظات نصية.' : entry.text,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onViewHistory != null)
                  TextButton.icon(
                    onPressed: widget.onViewHistory,
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('السجل'),
                  ),
                if (widget.onEdit != null) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('تعديل التأمل'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormHeader(context),
            const SizedBox(height: 12),
            _buildMoodSection(context),
            const SizedBox(height: 14),
            _buildInputSection(context),
            const SizedBox(height: 12),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'تأمل نهاية اليوم',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department,
                  size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                'سلسلة: ${widget.streakCount}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كيف تشعر اليوم؟',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: AppMoods.options.map((opt) {
            final isSelected = _selectedMood == opt.label;
            return ChoiceChip(
              avatar: Icon(opt.icon,
                  size: 18, color: isSelected ? null : opt.color),
              label: Text(opt.label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedMood = selected ? opt.label : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ماذا أنجزت أو ما هي ملاحظاتك اليوم؟',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          maxLines: 3,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'اكتب إنجازاتك، لحظات شكرك، أو ما تعلمته اليوم...',
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: _isSaving
            ? null
            : () async {
                final text = _controller.text.trim();
                if (text.isEmpty && _selectedMood == null) return;
                setState(() => _isSaving = true);
                try {
                  await widget.onSave(text, _selectedMood);
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check, size: 18),
        label: const Text('حفظ التأمل'),
      ),
    );
  }
}
