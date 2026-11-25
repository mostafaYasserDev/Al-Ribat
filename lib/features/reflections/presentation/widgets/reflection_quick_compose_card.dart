import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_moods.dart';

/// Quick compose card at the top of Reflections with optional one-tap mood shortcuts.
class ReflectionQuickComposeCard extends StatefulWidget {
  const ReflectionQuickComposeCard({
    super.key,
    required this.onCompose,
  });

  final void Function(
    BuildContext sourceContext,
    Color sourceColor, {
    String? initialMood,
  }) onCompose;

  @override
  State<ReflectionQuickComposeCard> createState() =>
      _ReflectionQuickComposeCardState();
}

class _ReflectionQuickComposeCardState
    extends State<ReflectionQuickComposeCard> {
  bool _pressed = false;

  static const _quickMoods = ['سعيد', 'هادئ', 'ممتن', 'متحمس'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardTheme.color ??
        (isDark ? const Color(0xFF111B2E) : Colors.white);
    final borderColor =
        theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.07);

    return RepaintBoundary(
      child: Builder(
        builder: (cardCtx) => AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 95),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 0.7),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.026),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onHighlightChanged: (v) {
                    if (_pressed != v) setState(() => _pressed = v);
                  },
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onCompose(cardCtx, cardColor);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'دوّن خاطرة أو تأملاً الآن…',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.62),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.85),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 0.6,
                  thickness: 0.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: _quickMoods.map((label) {
                      final mood = AppMoods.find(label);
                      if (mood == null) return const SizedBox.shrink();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onCompose(
                                cardCtx,
                                cardColor,
                                initialMood: mood.label,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: mood.color.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    mood.icon,
                                    size: 14,
                                    color: mood.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      mood.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: mood.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
