import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../application/ai_proactive_engine.dart';
import '../../domain/ai_proactive_alert.dart';
import '../ai_chat_screen.dart';

class AiProactiveBanner extends ConsumerWidget {
  const AiProactiveBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(aiProactiveAlertProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: alert == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Builder(
                builder: (bannerCtx) {
                  final (icon, accent) = switch (alert.type) {
                    ProactiveAlertType.schedulingConflict => (
                        Icons.schedule_rounded,
                        const Color(0xFFFF9500),
                      ),
                    ProactiveAlertType.commitmentNudge => (
                        Icons.auto_awesome_rounded,
                        const Color(0xFF5856D6),
                      ),
                    ProactiveAlertType.focusBalance => (
                        Icons.timer_outlined,
                        const Color(0xFF007AFF),
                      ),
                  };

                  return Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SettingsIconBadge(
                              icon: icon,
                              color: accent,
                              size: 34,
                              iconSize: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alert.body,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.4,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.75),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              tooltip: 'إخفاء اليوم',
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref
                                    .read(aiDismissedAlertsProvider.notifier)
                                    .dismissForToday(alert.id);
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                size: 17,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.48),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        PressableScale(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            AiChatScreen.open(
                              context,
                              sourceContext: bannerCtx,
                              sourceColor: accent.withValues(alpha: 0.14),
                              initialPrompt: alert.suggestedPrompt,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 15, color: accent),
                                const SizedBox(width: 6),
                                Text(
                                  'ناقش المساعد لحلها',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
