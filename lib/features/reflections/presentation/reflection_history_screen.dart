import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../core/ui/error_view.dart';
import '../../../core/ui_feedback.dart';
import '../domain/reflection_entry.dart';
import '../domain/reflection_search.dart';
import 'reflection_editor_screen.dart';
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
  bool _isGridView = true;
  bool _composePressed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewEditor({
    BuildContext? sourceContext,
    Color? sourceColor,
    double sourceRadius = 18,
  }) {
    HapticFeedback.lightImpact();
    ReflectionEditorScreen.open(
      context,
      sourceContext: sourceContext,
      sourceColor: sourceColor,
      sourceRadius: sourceRadius,
    );
  }

  void _openEditEditor(
    ReflectionEntry entry,
    BuildContext cardContext,
    Color bgColor,
  ) {
    HapticFeedback.lightImpact();
    ReflectionEditorScreen.open(
      context,
      entry: entry,
      sourceContext: cardContext,
      sourceColor: bgColor,
      sourceRadius: 16,
    );
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await ReflectionDialogs.confirmDelete(context);
    if (!confirmed || !mounted) return;
    await ref.read(reflectionsProvider.notifier).delete(id);
    lightSuccessHaptic();
    if (mounted) {
      appSnack(context, 'تم حذف الخاطرة.');
    }
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
          actions: [
            IconButton(
              icon: Icon(
                _isGridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view_rounded,
              ),
              tooltip: _isGridView ? 'عرض القائمة' : 'العرض الشبكي',
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _isGridView = !_isGridView);
              },
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (fabCtx) => FloatingActionButton(
            heroTag: 'reflections_fab',
            onPressed: () => _openNewEditor(
              sourceContext: fabCtx,
              sourceColor: Theme.of(context).colorScheme.primaryContainer,
              sourceRadius: 16,
            ),
            tooltip: 'خاطرة جديدة',
            child: const Icon(Icons.add),
          ),
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
    final filtered = _searchQuery.isEmpty
        ? entries
        : entries
            .where((e) => ReflectionSearch.matches(e, _searchQuery))
            .toList();

    final pinned = filtered.where((e) => e.isPinned).toList();
    final others = filtered.where((e) => !e.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
      children: [
        _buildSmartSearchBar(filtered.length),
        const SizedBox(height: 12),

        // Google Keep-style Empty Note Composer Card at the Top
        if (_searchQuery.isEmpty) ...[
          _buildQuickComposeBox(context),
          const SizedBox(height: 18),
        ],

        if (entries.isEmpty)
          _buildEmptyState(context)
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Center(
              child: Text(
                'لا توجد نتائج مطابقة للبحث.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ),
          )
        else ...[
          if (pinned.isNotEmpty) ...[
            _sectionLabel(context, 'مثبتة'),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey('pinned_$_isGridView'),
                child: _buildNotesLayout(pinned),
              ),
            ),
            if (others.isNotEmpty) const SizedBox(height: 18),
          ],
          if (others.isNotEmpty) ...[
            if (pinned.isNotEmpty) ...[
              _sectionLabel(context, 'أخرى'),
              const SizedBox(height: 8),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey('others_$_isGridView'),
                child: _buildNotesLayout(others),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildQuickComposeBox(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Builder(
      builder: (boxCtx) => AnimatedScale(
        scale: _composePressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onHighlightChanged: (v) {
              if (_composePressed != v) setState(() => _composePressed = v);
            },
            onTap: () => _openNewEditor(
              sourceContext: boxCtx,
              sourceColor: colorScheme.surfaceContainerLow,
              sourceRadius: 18,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'دوّن خاطرة أو تأملاً الآن…',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesLayout(List<ReflectionEntry> items) {
    if (!_isGridView) {
      return Column(
        children: [
          for (final entry in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ReflectionEntryCard(
                entry: entry,
                isGrid: false,
                onTap: (ctx, bg) => _openEditEditor(entry, ctx, bg),
                onTogglePin: () =>
                    ref.read(reflectionsProvider.notifier).togglePin(entry),
                onDelete: () => _handleDelete(entry.id),
              ),
            ),
        ],
      );
    }

    // True Google Keep-style 2-column staggered masonry layout
    final rightCol = <ReflectionEntry>[];
    final leftCol = <ReflectionEntry>[];
    for (var i = 0; i < items.length; i++) {
      if (i.isEven) {
        rightCol.add(items[i]);
      } else {
        leftCol.add(items[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              for (final entry in rightCol)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReflectionEntryCard(
                    entry: entry,
                    isGrid: true,
                    onTap: (ctx, bg) => _openEditEditor(entry, ctx, bg),
                    onTogglePin: () =>
                        ref.read(reflectionsProvider.notifier).togglePin(entry),
                    onDelete: () => _handleDelete(entry.id),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              for (final entry in leftCol)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReflectionEntryCard(
                    entry: entry,
                    isGrid: true,
                    onTap: (ctx, bg) => _openEditEditor(entry, ctx, bg),
                    onTogglePin: () =>
                        ref.read(reflectionsProvider.notifier).togglePin(entry),
                    onDelete: () => _handleDelete(entry.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSmartSearchBar(int matchCount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'ابحث في الخواطر، العناوين، المشاريع، أو الصلاة…',
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
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value.trim()),
        ),
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 6),
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 52,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 14),
          Text(
            'اضغط على "دوّن خاطرة" بالأعلى لتبدأ.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'مساحة هادئة لخواطرك وتأملاتك اليومية.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
