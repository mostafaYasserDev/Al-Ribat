import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../settings/presentation/widgets/settings_ui_components.dart';
import '../application/ai_providers.dart';
import '../domain/ai_local_model_spec.dart';
import '../domain/ai_provider_config.dart';
import 'widgets/ai_model_download_sheet.dart';

class AiSettingsPage extends ConsumerStatefulWidget {
  const AiSettingsPage({super.key});

  @override
  ConsumerState<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends ConsumerState<AiSettingsPage> {
  late final TextEditingController _keyController;
  late AiProviderType _permissionTab;
  bool _obscureKey = true;
  bool _savedFeedback = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(aiConfigProvider);
    _keyController = TextEditingController(text: config.groqApiKey ?? '');
    _permissionTab = config.type;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    HapticFeedback.lightImpact();
    final config = ref.read(aiConfigProvider);
    await ref.read(aiConfigProvider.notifier).updateConfig(
          config.copyWith(
            type: AiProviderType.groqCloud,
            groqApiKey: _keyController.text.trim(),
            hasCompletedOnboarding: true,
          ),
        );
    if (!mounted) return;
    setState(() => _savedFeedback = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedFeedback = false);
    });
  }

  Future<void> _openGroqConsole() async {
    final uri = Uri.parse('https://console.groq.com/keys');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aiConfigProvider);
    final perms = _permissionTab == AiProviderType.localLlm
        ? ref.watch(aiLocalPermissionsProvider)
        : ref.watch(aiCloudPermissionsProvider);
    Future<void> savePerms(dynamic next) {
      return _permissionTab == AiProviderType.localLlm
          ? ref
              .read(aiLocalPermissionsProvider.notifier)
              .updatePermissions(next)
          : ref
              .read(aiCloudPermissionsProvider.notifier)
              .updatePermissions(next);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const FrostedSettingsSliverAppBar(
            title: 'المساعد الذكي',
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SettingsSectionHeader(title: 'مزوِّد الذكاء الاصطناعي'),
                SettingsGroupCard(
                  dividerIndent: 16,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: AnimatedSegmentedControl<AiProviderType>(
                        options: const [
                          SegmentOption(
                            value: AiProviderType.groqCloud,
                            label: 'سحابي (Groq)',
                            icon: Icons.cloud_outlined,
                          ),
                          SegmentOption(
                            value: AiProviderType.localLlm,
                            label: 'محلي (على الجهاز)',
                            icon: Icons.smartphone_rounded,
                          ),
                        ],
                        selected: config.type,
                        onChanged: (next) async {
                          await ref
                              .read(aiConfigProvider.notifier)
                              .updateConfig(config.copyWith(type: next));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: _ProviderComparisonBox(type: config.type),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: config.type == AiProviderType.groqCloud
                      ? _buildGroqSection(theme, colorScheme, config)
                      : _buildLocalModelsPreview(theme, colorScheme, config),
                ),
                const SettingsSectionHeader(title: 'صلاحيات الوصول للبيانات'),
                SettingsGroupCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: AnimatedSegmentedControl<AiProviderType>(
                        options: const [
                          SegmentOption(
                            value: AiProviderType.groqCloud,
                            label: 'صلاحيات السحابي',
                            icon: Icons.cloud_outlined,
                          ),
                          SegmentOption(
                            value: AiProviderType.localLlm,
                            label: 'صلاحيات المحلي',
                            icon: Icons.smartphone_rounded,
                          ),
                        ],
                        selected: _permissionTab,
                        onChanged: (t) => setState(() => _permissionTab = t),
                      ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      iconColor: const Color(0xFFFF9500),
                      title: 'التنبيهات الاستباقية الذكية',
                      subtitle:
                          'تحليل محلي لتنبيهك عند ازدحام الجدول أو تراجع الالتزام',
                      value: config.proactiveAlertsEnabled,
                      onChanged: (v) =>
                          ref.read(aiConfigProvider.notifier).updateConfig(
                                config.copyWith(proactiveAlertsEnabled: v),
                              ),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.task_alt_rounded,
                      iconColor: const Color(0xFF34C759),
                      title: 'المهام والأنشطة',
                      subtitle: 'الاطلاع على مهامك وحالة إنجازها اليومي',
                      value: perms.allowActivities,
                      onChanged: (v) =>
                          savePerms(perms.copyWith(allowActivities: v)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.mosque_rounded,
                      iconColor: const Color(0xFF1F6F4A),
                      title: 'أوقات الصلاة',
                      subtitle:
                          'توزيع المهام حول الصلوات واكتشاف الفترات الضيقة',
                      value: perms.allowPrayer,
                      onChanged: (v) =>
                          savePerms(perms.copyWith(allowPrayer: v)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.folder_rounded,
                      iconColor: const Color(0xFFFF9500),
                      title: 'المشاريع',
                      subtitle: 'مشاركة أسماء المشاريع ونسب إنجازها',
                      value: perms.allowProjects,
                      onChanged: (v) =>
                          savePerms(perms.copyWith(allowProjects: v)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.timer_rounded,
                      iconColor: const Color(0xFF5856D6),
                      title: 'جلسات التركيز',
                      subtitle: 'مشاركة مدد جلسات التركيز الأسبوعية',
                      value: perms.allowWorkSessions,
                      onChanged: (v) =>
                          savePerms(perms.copyWith(allowWorkSessions: v)),
                    ),
                    SettingsSwitchTile(
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFFFF3B30),
                      title: 'التأملات الكاملة (نص حرفي)',
                      subtitle: 'حساسة — مشاركة نصوص خواطرك مباشرة',
                      value: perms.allowReflections,
                      onChanged: (v) =>
                          savePerms(perms.copyWith(allowReflections: v)),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      child: perms.allowReflections
                          ? const SizedBox.shrink()
                          : SettingsSwitchTile(
                              icon: Icons.shield_outlined,
                              iconColor: const Color(0xFF007AFF),
                              title: 'ملخص التأملات المحلي',
                              subtitle:
                                  'تلخيص محلي بدون نصوص حرفية، وتراجعه قبل المشاركة',
                              value: perms.allowReflectionSummary,
                              onChanged: (v) {
                                ref
                                    .read(aiReflectionSummaryApprovedProvider
                                        .notifier)
                                    .state = false;
                                savePerms(
                                    perms.copyWith(allowReflectionSummary: v));
                              },
                            ),
                    ),
                  ],
                ),
                const SettingsSectionFooter(
                  text:
                      'لا يُرسَل أي نوع بيانات مغلق في الصلاحيات أعلاه إلى المساعد نهائياً.',
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroqSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AiProviderConfig config,
  ) {
    return Column(
      key: const ValueKey('groq_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader(title: 'إعداد مفتاح Groq المجاني'),
        SettingsGroupCard(
          dividerIndent: 16,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'مفتاح Groq API',
                      hintText: 'gsk_...',
                      prefixIcon: const Icon(Icons.key_rounded, size: 19),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PressableScale(
                          onTap: _openGroqConsole,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.open_in_new_rounded,
                                    size: 16, color: colorScheme.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'احصل على مفتاح مجاني',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PressableScale(
                          onTap: _saveApiKey,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _savedFeedback
                                  ? const Color(0xFF34C759)
                                  : colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _savedFeedback
                                      ? Icons.check_rounded
                                      : Icons.save_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _savedFeedback ? 'تم الحفظ' : 'حفظ المفتاح',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1. افتح console.groq.com وسجّل بالبريد الإلكتروني.\n'
                    '2. اختر API Keys ثم Create API Key (مجاني بدون بطاقة).\n'
                    '3. انسخ المفتاح الذي يبدأ بـ gsk_ والصقه هنا.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'نموذج Groq المستخدم',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSegmentedControl<String>(
                    options: const [
                      SegmentOption(
                        value: AiProviderConfig.defaultGroqModel,
                        label: 'Qwen 3.8 27B (ممتاز)',
                      ),
                      SegmentOption(
                        value: AiProviderConfig.fastGroqModel,
                        label: 'GPT-OSS 20B (أسرع)',
                      ),
                    ],
                    selected: config.groqModel == AiProviderConfig.fastGroqModel
                        ? AiProviderConfig.fastGroqModel
                        : AiProviderConfig.defaultGroqModel,
                    onChanged: (m) => ref
                        .read(aiConfigProvider.notifier)
                        .updateConfig(config.copyWith(groqModel: m)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocalModelsPreview(
    ThemeData theme,
    ColorScheme colorScheme,
    AiProviderConfig config,
  ) {
    final downloaded =
        ref.watch(downloadedModelsProvider).valueOrNull ?? const {};
    final dlState = ref.watch(aiModelDownloadProvider);

    return Column(
      key: const ValueKey('local_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader(title: 'النماذج المحلية على الجهاز'),
        SettingsGroupCard(
          dividerIndent: 16,
          children: [
            for (final spec in LocalModelSpec.catalog)
              Builder(
                builder: (_) {
                  final path = downloaded[spec.id];
                  final isDownloaded = path != null;
                  final isThisDownloading = dlState.isDownloading &&
                      dlState.activeSpec?.id == spec.id;
                  final dlPct = (dlState.progress.fraction * 100).round();
                  final isSelected = isDownloaded &&
                      config.localModelId == spec.id &&
                      config.type == AiProviderType.localLlm;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SettingsIconBadge(
                              icon: Icons.memory_rounded,
                              color: Color(0xFF5856D6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          spec.displayName,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF5856D6)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          spec.badge,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF5856D6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    spec.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'الحجم: ${spec.sizeMb} ميجابايت · الذاكرة: ${(spec.requiredRamMb / 1000).toStringAsFixed(1)} جيجابايت · العربية: ${spec.arabicQualityLabel} · ${spec.speedNote}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: PressableScale(
                                onTap: () async {
                                  if (isDownloaded) {
                                    HapticFeedback.lightImpact();
                                    await ref
                                        .read(aiConfigProvider.notifier)
                                        .updateConfig(
                                          config.copyWith(
                                            type: AiProviderType.localLlm,
                                            localModelId: spec.id,
                                            localModelPath: path,
                                            hasCompletedOnboarding: true,
                                          ),
                                        );
                                  } else {
                                    await showModelDownloadSheet(context, spec);
                                  }
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF34C759)
                                            .withValues(alpha: 0.14)
                                        : colorScheme.primary
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isSelected
                                          ? 'مفعّل حالياً ✓'
                                          : isThisDownloading
                                              ? 'جاري التنزيل ($dlPct%)…'
                                              : (isDownloaded
                                                  ? 'تفعيل هذا النموذج'
                                                  : 'تنزيل · ${spec.sizeMb} ميجابايت'),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF34C759)
                                            : colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isDownloaded) ...[
                              const SizedBox(width: 8),
                              PressableScale(
                                onTap: () async {
                                  HapticFeedback.selectionClick();
                                  await ref
                                      .read(modelDownloadManagerProvider)
                                      .deleteModel(spec);
                                  if (config.localModelId == spec.id) {
                                    await ref
                                        .read(aiConfigProvider.notifier)
                                        .updateConfig(
                                          config.copyWith(
                                            type: AiProviderType.groqCloud,
                                            localModelId: null,
                                            localModelPath: null,
                                          ),
                                        );
                                  }
                                  ref.invalidate(downloadedModelsProvider);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30)
                                        .withValues(alpha: 0.11),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Text(
                                    'حذف',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFF3B30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ProviderComparisonBox extends StatelessWidget {
  const _ProviderComparisonBox({required this.type});

  final AiProviderType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCloud = type == AiProviderType.groqCloud;
    final tint = isCloud ? const Color(0xFF007AFF) : const Color(0xFF5856D6);
    final lines = isCloud
        ? const [
            '• مجاني بمفتاحك الشخصي بدون بطاقة ائتمان',
            '• لا تُستخدم بياناتك لتدريب النماذج السحابية',
            '• سرعة فائقة وجودة عالية جداً باللغة العربية',
            '• يتطلب اتصالاً بالإنترنت',
          ]
        : const [
            '• خصوصية مطلقة: لا شيء يغادر جهازك نهائياً',
            '• يعمل بدون إنترنت بعد تنزيل النموذج',
            '• يستهلك مساحة تخزين وذاكرة عشوائية أعلى أثناء التشغيل',
            '• يُشغَّل النموذج محلياً بالكامل داخل التطبيق',
          ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                l,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
            ),
        ],
      ),
    );
  }
}
