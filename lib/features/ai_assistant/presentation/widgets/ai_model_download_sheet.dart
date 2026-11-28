import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../application/ai_providers.dart';
import '../../data/model_download_manager.dart';
import '../../domain/ai_local_model_spec.dart';
import '../../domain/ai_provider_config.dart';

Future<bool?> showModelDownloadSheet(
  BuildContext context,
  LocalModelSpec spec,
) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _ModelDownloadSheet(spec: spec),
  );
}

class _ModelDownloadSheet extends ConsumerStatefulWidget {
  const _ModelDownloadSheet({required this.spec});

  final LocalModelSpec spec;

  @override
  ConsumerState<_ModelDownloadSheet> createState() =>
      _ModelDownloadSheetState();
}

class _ModelDownloadSheetState extends ConsumerState<_ModelDownloadSheet> {
  StreamSubscription<ModelDownloadProgress>? _sub;
  ModelDownloadProgress _progress = const ModelDownloadProgress(
    status: ModelDownloadStatus.idle,
  );
  bool _cancelled = false;

  @override
  void dispose() {
    _cancelled = true;
    _sub?.cancel();
    super.dispose();
  }

  void _startDownload() {
    HapticFeedback.lightImpact();
    setState(() {
      _cancelled = false;
      _progress = const ModelDownloadProgress(
        status: ModelDownloadStatus.downloading,
      );
    });

    final manager = ref.read(modelDownloadManagerProvider);
    _sub = manager
        .downloadModel(widget.spec, isCancelled: () => _cancelled)
        .listen((p) async {
      if (!mounted) return;
      setState(() => _progress = p);
      if (p.status == ModelDownloadStatus.completed && p.filePath != null) {
        final current = ref.read(aiConfigProvider);
        await ref.read(aiConfigProvider.notifier).updateConfig(
              current.copyWith(
                type: AiProviderType.localLlm,
                localModelId: widget.spec.id,
                localModelPath: p.filePath,
                hasCompletedOnboarding: true,
              ),
            );
        ref.invalidate(downloadedModelsProvider);
        if (mounted) Navigator.of(context).pop(true);
      }
    });
  }

  void _cancelOrClose() {
    _cancelled = true;
    _sub?.cancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spec = widget.spec;
    final isDownloading = _progress.status == ModelDownloadStatus.downloading;

    final receivedMb =
        (_progress.receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = _progress.totalBytes > 0
        ? (_progress.totalBytes / (1024 * 1024)).toStringAsFixed(0)
        : spec.sizeMb.toString();
    final speedMb =
        (_progress.bytesPerSecond / (1024 * 1024)).toStringAsFixed(1);

    return Container(
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
                '• مساحة التخزين المطلوبة: ${spec.sizeMb} MB\n'
                '• ذاكرة RAM حرة موصى بها: ${(spec.requiredRamMb / 1000).toStringAsFixed(1)} GB\n'
                '• يُنصح بالتنزيل عبر شبكة Wi-Fi.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
              ),
            ),
            if (_progress.status == ModelDownloadStatus.error &&
                _progress.errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _progress.errorMessage!,
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
                  value: _progress.totalBytes > 0 ? _progress.fraction : null,
                  minHeight: 7,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$receivedMb / $totalMb MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$speedMb MB/s',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PressableScale(
                    onTap: _cancelOrClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isDownloading
                            ? const Color(0xFFFF3B30).withValues(alpha: 0.12)
                            : colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          isDownloading ? 'إلغاء التنزيل' : 'إغلاق',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDownloading
                                ? const Color(0xFFFF3B30)
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isDownloading) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: PressableScale(
                      onTap: _startDownload,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
