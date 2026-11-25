import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/theme/app_moods.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../../prayer/domain/prayer_phase.dart';
import '../domain/reflection_entry.dart';
import 'widgets/add_reflection_sheet.dart';
import 'widgets/reflection_dialogs.dart';
import 'widgets/reflection_entry_card.dart';
import 'widgets/reflection_mood_summary.dart';

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
            appSnack(ctx, 'حُفظ التأمل مع التاريخ والرباط.');
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

  bool _matchesQuery(ReflectionEntry entry, String query) {
    final q = query.toLowerCase();
    return entry.text.toLowerCase().contains(q) ||
        (entry.mood?.toLowerCase().contains(q) ?? false) ||
        (entry.prayerPhaseName?.toLowerCase().contains(q) ?? false) ||
        (entry.linkedContextTitle?.toLowerCase().contains(q) ?? false);
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
      if (_searchQuery.isNotEmpty && !_matchesQuery(e, _searchQuery)) {
        return false;
      }
      if (_filterMood != null && e.mood != _filterMood) {
        return false;
      }
      return true;
    }).toList();

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
        ReflectionMoodSummary(entries: entries),
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
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final item = groupedItems[index];
                    if (item is String) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(
                          item,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      );
                    }
                    final entry = item as ReflectionEntry;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'بحث في التأملات، المزاج، أو المشاريع...',
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
}
