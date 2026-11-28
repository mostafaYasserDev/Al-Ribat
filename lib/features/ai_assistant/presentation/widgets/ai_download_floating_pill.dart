import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../application/ai_providers.dart';
import '../../data/model_download_manager.dart';
import 'ai_model_download_sheet.dart';

class AiDownloadFloatingPill extends ConsumerWidget {
  const AiDownloadFloatingPill({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dlState = ref.watch(aiModelDownloadProvider);
    final spec = dlState.activeSpec;
    final status = dlState.progress.status;
    final visible = spec != null &&
        (status == ModelDownloadStatus.downloading ||
            status == ModelDownloadStatus.completed);

    return SafeArea(
      bottom: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: !visible
            ? const SizedBox.shrink()
            : Padding(
                key: ValueKey('${spec.id}_${status.name}'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Material(
                      color: Colors.transparent,
                      child: PressableScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          final navCtx =
                              navigatorKey?.currentContext ?? context;
                          showModelDownloadSheet(navCtx, spec);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: _PillBody(
                              specName: spec.displayName,
                              progress: dlState.progress,
                              onCancel: () {
                                HapticFeedback.selectionClick();
                                if (status == ModelDownloadStatus.downloading) {
                                  ref
                                      .read(aiModelDownloadProvider.notifier)
                                      .cancelDownload();
                                } else {
                                  ref
                                      .read(aiModelDownloadProvider.notifier)
                                      .clearStatus();
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _PillBody extends StatelessWidget {
  const _PillBody({
    required this.specName,
    required this.progress,
    required this.onCancel,
  });

  final String specName;
  final ModelDownloadProgress progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDone = progress.status == ModelDownloadStatus.completed;
    final accent = isDone ? const Color(0xFF34C759) : const Color(0xFF5856D6);
    final pct = (progress.fraction * 100).round();
    final speedMb =
        (progress.bytesPerSecond / (1024 * 1024)).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.downloading_rounded,
                  size: 17,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDone ? 'تم تحميل $specName' : 'جاري تنزيل $specName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isDone
                          ? 'جاهز ومفعّل للمحادثة الآن'
                          : '$pct% · $speedMb ميجابايت/ث',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onCancel,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
          if (!isDone) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.totalBytes > 0 ? progress.fraction : null,
                minHeight: 3.5,
                color: accent,
                backgroundColor: accent.withValues(alpha: 0.14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
