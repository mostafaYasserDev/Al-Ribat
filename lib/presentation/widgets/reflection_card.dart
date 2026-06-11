import 'package:flutter/material.dart';

class ReflectionCard extends StatefulWidget {
  const ReflectionCard({
    super.key,
    required this.streakCount,
    required this.onSave,
  });

  final int streakCount;
  final Future<void> Function(String text, String? mood) onSave;

  @override
  State<ReflectionCard> createState() => _ReflectionCardState();
}

class _ReflectionCardState extends State<ReflectionCard> {
  final _controller = TextEditingController();
  bool _submitted = false;
  String? _selectedMood;

  static const _moods = [
    (icon: Icons.sentiment_very_satisfied, label: 'سعيد'),
    (icon: Icons.cloud_outlined, label: 'هادئ'),
    (icon: Icons.favorite_border, label: 'ممتن'),
    (icon: Icons.bolt, label: 'متحمس'),
    (icon: Icons.battery_alert, label: 'مرهق'),
    (icon: Icons.sentiment_neutral, label: 'متوتر'),
    (icon: Icons.sentiment_dissatisfied, label: 'حزين'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تأمل نهاية اليوم',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('سلسلة الإنجاز الحالية: ${widget.streakCount}'),
            const SizedBox(height: 10),
            if (_submitted)
              const Text('أحسنت، تم حفظ تأملك لليوم.')
            else ...[
              const Text('كيف تشعر اليوم؟'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood.label;
                  return ChoiceChip(
                    avatar: Icon(mood.icon, size: 18),
                    label: Text(mood.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedMood = selected ? mood.label : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('ماذا أنجزت أو ما هي ملاحظاتك اليوم؟'),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'اكتب إنجازاتك أو ملاحظاتك...',
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () async {
                  if (_controller.text.trim().isEmpty && _selectedMood == null) return;
                  await widget.onSave(_controller.text.trim(), _selectedMood);
                  setState(() => _submitted = true);
                },
                child: const Text('حفظ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
