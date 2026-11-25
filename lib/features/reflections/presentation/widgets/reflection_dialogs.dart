import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/core/theme/app_moods.dart';
import '../../domain/reflection_entry.dart';

abstract final class ReflectionDialogs {
  static Future<bool> confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التأمل'),
        content: const Text(
          'هل أنت متأكد من حذف هذا التأمل؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void showEditHistory(BuildContext context, ReflectionEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('سجل التعديلات', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (entry.editHistory.isEmpty)
                const Text('لا توجد تعديلات سابقة لهذا التأمل.')
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: entry.editHistory.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final h = entry.editHistory.reversed.toList()[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat('d MMM yyyy · h:mm a', 'ar')
                                    .format(h.editedAt),
                                style: Theme.of(ctx)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Theme.of(ctx).colorScheme.primary,
                                    ),
                              ),
                              if (h.oldMood != null) ...[
                                const SizedBox(width: 8),
                                MoodDisplayChip(mood: h.oldMood!, dense: true),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(h.oldText),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void showFullText(
    BuildContext context,
    ReflectionEntry entry, {
    VoidCallback? onOpenHistory,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('التأمل كاملاً',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  if (entry.editHistory.isNotEmpty && onOpenHistory != null)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onOpenHistory();
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('السجل'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (entry.mood != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: MoodDisplayChip(mood: entry.mood!),
                ),
                const SizedBox(height: 12),
              ],
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    entry.text,
                    textAlign: TextAlign.right,
                    style: Theme.of(ctx)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
