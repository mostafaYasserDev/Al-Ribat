import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../application/ai_providers.dart';
import '../../data/model_download_manager.dart';
import '../../domain/ai_local_model_spec.dart';

Future<bool?> showModelDownloadSheet(
  BuildContext context,
  LocalModelSpec spec,
) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => _ModelDownloadSheet(spec: spec),
  );
}

class _ModelDownloadSheet extends ConsumerWidget {
  const _ModelDownloadSheet({required this.spec});

  final LocalModelSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dlState = ref.watch(aiModelDownloadProvider);
    final isThisSpec = dlState.activeSpec?.id == spec.id;
    final progress = isThisSpec
        ? dlState.progress
        : const ModelDownloadProgress(status: ModelDownloadStatus.idle);
    final isDownloading = progress.status == ModelDownloadStatus.downloading;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receivedMb =
        (progress.receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = progress.totalBytes > 0
        ? (progress.totalBytes / (1024 * 1024)).toStringAsFixed(0)
        : spec.sizeMb.toString();
    final speedMb =
        (progress.bytesPerSecond / (1024 * 1024)).toStringAsFixed(1);
    final ramGb = (spec.requiredRamMb / 1000).toStringAsFixed(1);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SettingsIconBadge(
                    icon: Icons.memory_rounded,
                    color: Color(0xFF5856D6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      spec.displayName,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '⚠️ تنبيه الموارد قبل التنزيل:\n'
                  '• مساحة التخزين المطلوبة: ${spec.sizeMb} ميجابايت\n'
                  '• الذاكرة العشوائية الموصى بها: $ramGb جيجابايت\n'
                  '• يُنصح بالتنزيل عبر شبكة واي فاي',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.55),
                ),
              ),
              if (progress.status == ModelDownloadStatus.error &&
                  progress.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  progress.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFFF3B30),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (isDownloading) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.totalBytes > 0 ? progress.fraction : null,
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$receivedMb / $totalMb ميجابايت',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$speedMb ميجابايت/ث',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              if (isDownloading)
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(aiModelDownloadProvider.notifier)
                              .cancelDownload();
                          Navigator.of(context).pop(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFF3B30).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Center(
                            child: Text(
                              'إلغاء التنزيل',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF3B30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: PressableScale(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(false);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Center(
                            child: Text(
                              'متابعة في الخلفية',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Center(
                            child: Text(
                              'إغلاق',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: PressableScale(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(aiModelDownloadProvider.notifier)
                              .startDownload(spec);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Center(
                            child: Text(
                              'بدء التنزيل',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
    );
  }
}
