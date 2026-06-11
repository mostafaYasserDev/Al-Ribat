import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../application/providers.dart';
import '../../core/ui_feedback.dart';
import '../../domain/entities/reflection_entry.dart';
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

  void _openEdit(BuildContext context, WidgetRef ref, ReflectionEntry entry) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AddReflectionSheet(
        initialText: entry.text,
        onSave: (text) async {
          await ref.read(reflectionsProvider.notifier).updateReflection(entry, text);
          if (ctx.mounted) {
            lightSuccessHaptic();
            appSnack(ctx, 'تم تعديل التأمل بنجاح.');
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التأمل'),
        content: const Text('هل أنت متأكد من حذف هذا التأمل؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(reflectionsProvider.notifier).delete(id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                lightSuccessHaptic();
                appSnack(context, 'تم حذف التأمل.');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showEditHistory(BuildContext context, ReflectionEntry entry) {
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
              Text('سجل التعديلات', style: Theme.of(context).textTheme.titleLarge),
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
                          Text(
                            DateFormat('d MMM yyyy · h:mm a', 'ar').format(h.editedAt),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
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

  void _showFullReflection(BuildContext context, ReflectionEntry entry, WidgetRef ref) {
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
                  Text('التأمل كاملاً', style: Theme.of(context).textTheme.titleLarge),
                  if (entry.editHistory.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showEditHistory(context, entry);
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('السجل'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    entry.text,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isLong(String text) {
    return text.length > 150 || text.split('\n').length > 4;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReflections = ref.watch(reflectionsProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الحالات المزاجية والتأملات')),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE · d MMM yyyy · h:mm a', 'ar').format(item.createdAt),
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                  ),
                                  if (item.editHistory.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _showEditHistory(context, item),
                                      child: Text(
                                        'تم التعديل (شاهد السجل)',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Theme.of(context).colorScheme.secondary,
                                              decoration: TextDecoration.underline,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _openEdit(context, ref, item);
                                } else if (val == 'delete') {
                                  _confirmDelete(context, ref, item.id);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('تعديل'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
                                      const SizedBox(width: 8),
                                      Text('حذف', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (item.mood != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.mood!,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (_isLong(item.text)) ...[
                          Text(
                            item.text,
                            textAlign: TextAlign.right,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => _showFullReflection(context, item, ref),
                              child: const Text('عرض التأمل'),
                            ),
                          ),
                        ] else ...[
                          SelectableText(
                            item.text,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.55),
                          ),
                        ],
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
