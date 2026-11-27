import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:al_ribat/core/theme/app_moods.dart';
import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../domain/reflection_entry.dart';

abstract final class ReflectionDialogs {
  static Future<bool> confirmDelete(BuildContext context) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, _, __) => const Directionality(
        textDirection: TextDirection.rtl,
        child: _ConfirmDeleteDialog(),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scale = Tween<double>(begin: 0.86, end: 1.0).animate(
          CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          ),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(ctx).pop(false),
                child: FadeTransition(
                  opacity: curved,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.26),
                    ),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: curved,
              child: ScaleTransition(scale: scale, child: child),
            ),
          ],
        );
      },
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

class _ConfirmDeleteDialog extends StatelessWidget {
  const _ConfirmDeleteDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xFF142035).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.98);
    const destructive = Color(0xFFFF3B30);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: isDark ? 0.12 : 0.08),
                  width: 0.7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SettingsIconBadge(
                    icon: Icons.delete_outline_rounded,
                    color: destructive,
                    size: 44,
                    iconSize: 22,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حذف الخاطرة؟',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سيتم حذف هذا التأمل من قائمتك، مع إمكانية التراجع فوراً بعد الحذف.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Material(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: isDark ? 0.35 : 0.7),
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop(false);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'إلغاء',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PressableScale(
                          onTap: () => Navigator.of(context).pop(true),
                          child: Material(
                            color: destructive.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                Navigator.of(context).pop(true);
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: Text(
                                    'حذف',
                                    style: TextStyle(
                                      color: destructive,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
