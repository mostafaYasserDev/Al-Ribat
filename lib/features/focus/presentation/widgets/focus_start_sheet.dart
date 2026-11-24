import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:al_ribat/core/ui_feedback.dart';
import '../../application/active_focus_notifier.dart';

class FocusStartSheet {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final active = ref.read(activeFocusProvider);
    if (active != null) {
      appSnack(
        context,
        'هناك جلسة نشطة بالفعل. أكملها أو أوقفها قبل بدء جلسة جديدة.',
      );
      return;
    }

    final nameController = TextEditingController(text: 'جلسة تركيز');
    var minutes = 25;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'بدء جلسة تركيز جديدة',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الجلسة أو الهدف',
                  hintText: 'مثال: قراءة ورد، مراجعة درس، برمجة...',
                ),
              ),
              const SizedBox(height: 14),
              Text('مدة الجلسة', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [15, 25, 45, 60].map((m) {
                  return ChoiceChip(
                    label: Text('$m دقيقة'),
                    selected: minutes == m,
                    onSelected: (sel) {
                      if (sel) setModal(() => minutes = m);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'أو حدد مدة مخصصة (بالدقائق)',
                  hintText: 'مثال: 90',
                ),
                onChanged: (val) {
                  final m = int.tryParse(val);
                  if (m != null && m > 0) {
                    setModal(() => minutes = m);
                  }
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  final title = nameController.text.trim().isEmpty
                      ? 'جلسة تركيز'
                      : nameController.text.trim();
                  Navigator.pop(ctx);
                  await ref.read(activeFocusProvider.notifier).startSession(
                        title: title,
                        plannedMinutes: minutes,
                      );
                  lightSuccessHaptic();
                  if (context.mounted) {
                    appSnack(context, 'بدأت الجلسة — توكل على الله وركز.');
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('بدء الجلسة'),
              ),
            ],
          ),
        ),
      ),
    );
    nameController.dispose();
  }
}
