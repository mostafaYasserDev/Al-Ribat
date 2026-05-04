import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../application/providers.dart';
import '../../core/ui_feedback.dart';
import '../widgets/add_reflection_sheet.dart';

class ReflectionHistoryScreen extends ConsumerWidget {
  const ReflectionHistoryScreen({super.key});

  void _openAdd(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AddReflectionSheet(
        onSave: (text) async {
          await ref.read(reflectionsProvider.notifier).add(text);
          if (ctx.mounted) {
            lightSuccessHaptic();
            appSnack(ctx, 'حُفظ التأمل مع التاريخ والوقت.');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReflections = ref.watch(reflectionsProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التأملات')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAdd(context, ref),
          icon: const Icon(Icons.edit_note),
          label: const Text('تأمل جديد'),
        ),
        body: asyncReflections.when(
          data: (entries) {
            if (entries.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'سجّل لحظة صفاء بعد يومك.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'كل سطر تكتبه هنا يبني وعياً بهدوء — ابدأ بتأمل قصير عن نيتك أو شكرك.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _openAdd(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('أضف أول تأمل'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = entries[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          DateFormat('EEEE · d MMM yyyy · h:mm a', 'ar').format(item.createdAt),
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          item.text,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('تعذر تحميل السجل: $error')),
        ),
      ),
    );
  }
}
