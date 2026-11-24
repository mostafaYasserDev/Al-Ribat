import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../application/providers.dart';
import '../../../core/theme/app_moods.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../domain/reflection_entry.dart';
import 'widgets/add_reflection_sheet.dart';

class ReflectionHistoryScreen extends ConsumerStatefulWidget {
  const ReflectionHistoryScreen({super.key});

  @override
  ConsumerState<ReflectionHistoryScreen> createState() =>
      _ReflectionHistoryScreenState();
}

class _ReflectionHistoryScreenState
    extends ConsumerState<ReflectionHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterMood;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AddReflectionSheet(
        onSave: (text, mood) async {
          await ref.read(reflectionsProvider.notifier).add(text, mood: mood);
          if (ctx.mounted) {
            lightSuccessHaptic();
            appSnack(ctx, 'حُفظ التأمل مع التاريخ والوقت.');
          }
        },
      ),
    );
  }

  void _showEditSheet(ReflectionEntry entry) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => AddReflectionSheet(
        initialText: entry.text,
        initialMood: entry.mood,
        onSave: (text, mood) async {
          await ref.read(reflectionsProvider.notifier).updateReflection(
                entry,
                text,
                newMood: mood,
              );
          if (ctx.mounted) {
            lightSuccessHaptic();
            appSnack(ctx, 'تم تعديل التأمل بنجاح.');
          }
        },
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التأمل'),
        content: const Text(
          'هل أنت متأكد من حذف هذا التأمل؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
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
              }
              if (mounted) {
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

  void _showEditHistory(ReflectionEntry entry) {
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
              Text('سجل التعديلات',
                  style: Theme.of(context).textTheme.titleLarge),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
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

  void _showFullText(ReflectionEntry entry) {
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
                      style: Theme.of(context).textTheme.titleLarge),
                  if (entry.editHistory.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showEditHistory(entry);
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncReflections = ref.watch(reflectionsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الحالات المزاجية والتأملات')),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'reflections_fab',
          onPressed: _showAddSheet,
          icon: const Icon(Icons.edit_note),
          label: const Text('تأمل جديد'),
        ),
        body: asyncReflections.when(
          data: (entries) => _buildBody(entries),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AppErrorView(
            error: e,
            onRetry: () => ref.invalidate(reflectionsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<ReflectionEntry> entries) {
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
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add),
                label: const Text('أضف أول تأمل'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = entries.where((e) {
      if (_searchQuery.isNotEmpty && !e.text.contains(_searchQuery)) {
        return false;
      }
      if (_filterMood != null && e.mood != _filterMood) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد نتائج مطابقة للبحث.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildEntryCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث في التأملات والخواطر...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('الكل'),
                selected: _filterMood == null,
                onSelected: (sel) {
                  if (sel) setState(() => _filterMood = null);
                },
              ),
              const SizedBox(width: 6),
              ...AppMoods.options.map((opt) {
                final isSel = _filterMood == opt.label;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: ChoiceChip(
                    avatar: Icon(opt.icon,
                        size: 16, color: isSel ? null : opt.color),
                    label: Text(opt.label),
                    selected: isSel,
                    onSelected: (sel) {
                      setState(() => _filterMood = sel ? opt.label : null);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(ReflectionEntry entry) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
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
                        DateFormat('EEEE · d MMM yyyy · h:mm a', 'ar')
                            .format(entry.createdAt),
                        textAlign: TextAlign.right,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      if (entry.editHistory.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _showEditHistory(entry),
                          child: Text(
                            'تم التعديل (شاهد السجل)',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (entry.mood != null) MoodDisplayChip(mood: entry.mood!),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditSheet(entry);
                    } else if (val == 'delete') {
                      _confirmDelete(entry.id);
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
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'حذف',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildEntryText(entry),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryText(ReflectionEntry entry) {
    final isLong = entry.text.length > 150 || entry.text.split('\n').length > 4;

    if (isLong) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            entry.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showFullText(entry),
              child: const Text('قراءة المزيد'),
            ),
          ),
        ],
      );
    }

    return Text(
      entry.text,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
    );
  }
}
