import 'package:flutter/material.dart';

class AddReflectionSheet extends StatefulWidget {
  const AddReflectionSheet({super.key, required this.onSave});

  final Future<void> Function(String text) onSave;

  @override
  State<AddReflectionSheet> createState() => _AddReflectionSheetState();
}

class _AddReflectionSheetState extends State<AddReflectionSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          Text('تأمل جديد', style: Theme.of(context).textTheme.titleLarge),
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
    );
  }
}
