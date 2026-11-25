import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../../prayer/domain/prayer_phase.dart';
import '../domain/reflection_entry.dart';
import '../domain/reflection_search.dart';
import 'widgets/add_reflection_sheet.dart';
import 'widgets/reflection_dialogs.dart';
import 'widgets/reflection_entry_card.dart';

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
        onSave: (text, mood, linkedContext) async {
          final prayerName =
              ref.read(dayStateProvider).currentPrayerPhase.arabicName;
          await ref.read(reflectionsProvider.notifier).add(
                text,
                mood: mood,
                prayerPhaseName: prayerName,
                linkedContextTitle: linkedContext,
              );
          if (ctx.mounted) {
            lightSuccessHaptic();
            appSnack(ctx, 'حُفظ التأمل بنجاح.');
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
        initialContextTitle: entry.linkedContextTitle,
        onSave: (text, mood, linkedContext) async {
          await ref.read(reflectionsProvider.notifier).updateReflection(
                entry,
                text,
                newMood: mood,
                linkedContextTitle: linkedContext,
                clearLinkedContext: linkedContext == null,
              );
          if (ctx.mounted) {
            lightSuccessHaptic();
            appSnack(ctx, 'تم تعديل التأمل بنجاح.');
          }
        },
      ),
    );
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await ReflectionDialogs.confirmDelete(context);
    if (!confirmed || !mounted) return;
    await ref.read(reflectionsProvider.notifier).delete(id);
    lightSuccessHaptic();
    if (mounted) {
      appSnack(context, 'تم حذف التأمل.');
    }
  }

  String _groupLabel(DateTime createdAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final entryDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final diffDays = today.difference(entryDay).inDays;

    if (diffDays <= 0) return 'اليوم';
    if (diffDays == 1) return 'أمس';
    if (diffDays < 7) return 'هذا الأسبوع';
    return 'سابقاً';
  }

  @override
  Widget build(BuildContext context) {
    final asyncReflections = ref.watch(reflectionsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'التأملات والخواطر',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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

    final filtered = _searchQuery.isEmpty
        ? entries
        : entries
            .where((e) => ReflectionSearch.matches(e, _searchQuery))
            .toList();

    final now = DateTime.now();
    final groupedItems = <Object>[];
    String? lastGroup;
    for (final entry in filtered) {
      final group = _groupLabel(entry.createdAt, now);
      if (group != lastGroup) {
        groupedItems.add(group);
        lastGroup = group;
      }
      groupedItems.add(entry);
    }

    return Column(
      children: [
        _buildSmartSearchBar(filtered.length),
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
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final item = groupedItems[index];
                    if (item is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final entry = item as ReflectionEntry;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReflectionEntryCard(
                        entry: entry,
                        onEdit: () => _showEditSheet(entry),
                        onDelete: () => _handleDelete(entry.id),
                        onShowEditHistory: () =>
                            ReflectionDialogs.showEditHistory(context, entry),
                        onReadMore: () => ReflectionDialogs.showFullText(
                          context,
                          entry,
                          onOpenHistory: () =>
                              ReflectionDialogs.showEditHistory(context, entry),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSmartSearchBar(int matchCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث في الخواطر، المشاريع، الصلاة، أو الشعور…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Text(
                'نتائج البحث: $matchCount',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
