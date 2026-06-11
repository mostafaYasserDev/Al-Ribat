import 'package:flutter/material.dart';

class AddReflectionSheet extends StatefulWidget {
  const AddReflectionSheet({super.key, required this.onSave, this.initialText});

  final Future<void> Function(String text) onSave;
  final String? initialText;

  @override
  State<AddReflectionSheet> createState() => _AddReflectionSheetState();
}

class _AddReflectionSheetState extends State<AddReflectionSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.initialText != null ? 'تعديل التأمل' : 'تأمل جديد', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'يُحفظ تلقائياً مع التاريخ واليوم والساعة.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 10,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'اكتب ما يخطر ببالك…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final t = _controller.text.trim();
                if (t.isEmpty) return;
                await widget.onSave(t);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('حفظ في السجل'),
            ),
          ],
        ),
      ),
    );
  }
}
