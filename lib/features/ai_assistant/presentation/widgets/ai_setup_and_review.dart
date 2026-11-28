import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../application/ai_providers.dart';
import '../../domain/ai_context_snapshot.dart';
import '../../domain/ai_local_model_spec.dart';
import '../../domain/ai_provider_config.dart';
import '../ai_settings_page.dart';
import 'ai_model_download_sheet.dart';

class AiSetupView extends ConsumerStatefulWidget {
  const AiSetupView({super.key});

  @override
  ConsumerState<AiSetupView> createState() => _AiSetupViewState();
}

class _AiSetupViewState extends ConsumerState<AiSetupView> {
  final _keyController = TextEditingController();
  int _step = 0; // 0..3
  AiProviderType _selectedType = AiProviderType.groqCloud;
  bool _obscure = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final key = _keyController.text.trim();
    if (_selectedType == AiProviderType.groqCloud && key.isEmpty) return;
    HapticFeedback.lightImpact();
    final current = ref.read(aiConfigProvider);
    await ref.read(aiConfigProvider.notifier).updateConfig(
          current.copyWith(
            type: _selectedType,
            groqApiKey: _selectedType == AiProviderType.groqCloud ? key : null,
            hasCompletedOnboarding: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepHeaderBar(currentStep: _step, totalSteps: 4),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: switch (_step) {
              0 => _buildStepWelcome(theme, colorScheme),
              1 => _buildStepChooseProvider(theme, colorScheme),
              2 => _buildStepConfigureProvider(theme, colorScheme),
              _ => _buildStepPermissions(theme, colorScheme),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepWelcome(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('step_0'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF5856D6).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF5856D6).withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            children: [
              const SettingsIconBadge(
                icon: Icons.auto_awesome_rounded,
                color: Color(0xFF5856D6),
                size: 50,
                iconSize: 26,
              ),
              const SizedBox(height: 12),
              Text(
                'مرحباً بك في RibatAI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'مساعدك الشخصي لتنظيم المهام حول الصلوات، اكتشاف تعارضات الوقت، واقتراح مشاريع ومهام جديدة بضغطة زر — مع تحكمك الكامل في الخصوصية.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.55,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryOnboardingButton(
          label: 'ابدأ الإعداد (4 خطوات سريعة)',
          onTap: () => setState(() => _step = 1),
        ),
      ],
    );
  }

  Widget _buildStepChooseProvider(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'اختر طريقة التشغيل المناسبة لك',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _ProviderOptionCard(
          selected: _selectedType == AiProviderType.groqCloud,
          icon: Icons.cloud_outlined,
          color: const Color(0xFF007AFF),
          title: 'سحابي (Groq) — موصى به حالياً',
          bullets: const [
            'مجاني بمفتاح شخصي (بدون بطاقة ائتمان)',
            'Groq لا يستخدم بياناتك لتدريب نماذجه',
            'يعمل بسرعة فائقة على أي جهاز متصل بالإنترنت',
          ],
          onTap: () => setState(() => _selectedType = AiProviderType.groqCloud),
        ),
        const SizedBox(height: 10),
        _ProviderOptionCard(
          selected: _selectedType == AiProviderType.localLlm,
          icon: Icons.smartphone_rounded,
          color: const Color(0xFF5856D6),
          title: 'محلي على الجهاز (قريباً في المرحلة 4)',
          bullets: const [
            'خصوصية مطلقة 100% — لا شيء يغادر هاتفك',
            'يعمل بدون إنترنت بعد تنزيل النموذج',
            'يحتاج مساحة تخزين وذاكرة RAM كافية',
          ],
          onTap: () => setState(() => _selectedType = AiProviderType.localLlm),
        ),
        const SizedBox(height: 14),
        _StepNavRow(
          onBack: () => setState(() => _step = 0),
          onNext: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  Widget _buildStepConfigureProvider(ThemeData theme, ColorScheme colorScheme) {
    if (_selectedType == AiProviderType.localLlm) {
      return Column(
        key: const ValueKey('step_2_local'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsGroupCard(
            dividerIndent: 16,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'النماذج المحلية الثلاثة المتاحة في المرحلة 4 (تذكير بالمساحة وRAM قبل التنزيل):',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final spec in LocalModelSpec.catalog)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${spec.displayName} (${spec.badge})',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الحجم: ${spec.sizeMb} MB · RAM: ${(spec.requiredRamMb / 1000).toStringAsFixed(1)} GB · العربية: ${spec.arabicQualityLabel}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.62),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PressableScale(
                        onTap: () => showModelDownloadSheet(context, spec),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'تنزيل',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _StepNavRow(
            onBack: () => setState(() => _step = 1),
            nextLabel: 'استخدم Groq حالياً',
            onNext: () => setState(() {
              _selectedType = AiProviderType.groqCloud;
            }),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('step_2_groq'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroupCard(
          dividerIndent: 16,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'أدخل مفتاح Groq المجاني',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1. افتح console.groq.com وسجّل بالبريد.\n'
                    '2. أنشئ API Key مجاني وانسخه هنا.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscure,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'مفتاح Groq API',
                      hintText: 'gsk_...',
                      prefixIcon: const Icon(Icons.key_rounded, size: 19),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PressableScale(
                    onTap: () => launchUrl(
                      Uri.parse('https://console.groq.com/keys'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'فتح console.groq.com',
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
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _StepNavRow(
          onBack: () => setState(() => _step = 1),
          onNext: _keyController.text.trim().isEmpty
              ? null
              : () => setState(() => _step = 3),
        ),
      ],
    );
  }

  Widget _buildStepPermissions(ThemeData theme, ColorScheme colorScheme) {
    final isLocal = _selectedType == AiProviderType.localLlm;
    final perms = isLocal
        ? ref.watch(aiLocalPermissionsProvider)
        : ref.watch(aiCloudPermissionsProvider);
    Future<void> savePerms(dynamic next) {
      return isLocal
          ? ref
              .read(aiLocalPermissionsProvider.notifier)
              .updatePermissions(next)
          : ref
              .read(aiCloudPermissionsProvider.notifier)
              .updatePermissions(next);
    }

    return Column(
      key: const ValueKey('step_3_perms'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isLocal
              ? 'حدّد صلاحيات النموذج المحلي'
              : 'حدّد صلاحيات النموذج السحابي',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SettingsGroupCard(
          children: [
            SettingsSwitchTile(
              icon: Icons.task_alt_rounded,
              iconColor: const Color(0xFF34C759),
              title: 'المهام والأنشطة',
              value: perms.allowActivities,
              onChanged: (v) => savePerms(perms.copyWith(allowActivities: v)),
            ),
            SettingsSwitchTile(
              icon: Icons.mosque_rounded,
              iconColor: const Color(0xFF1F6F4A),
              title: 'أوقات الصلاة',
              value: perms.allowPrayer,
              onChanged: (v) => savePerms(perms.copyWith(allowPrayer: v)),
            ),
            SettingsSwitchTile(
              icon: Icons.folder_rounded,
              iconColor: const Color(0xFFFF9500),
              title: 'المشاريع',
              value: perms.allowProjects,
              onChanged: (v) => savePerms(perms.copyWith(allowProjects: v)),
            ),
            SettingsSwitchTile(
              icon: Icons.shield_outlined,
              iconColor: const Color(0xFF007AFF),
              title: 'ملخص التأملات المحلي (بمراجعتك)',
              value: perms.allowReflectionSummary,
              onChanged: (v) =>
                  savePerms(perms.copyWith(allowReflectionSummary: v)),
            ),
            SettingsNavTile(
              icon: Icons.tune_rounded,
              iconColor: const Color(0xFF5856D6),
              title: 'كافة الصلاحيات والإعدادات',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AiSettingsPage(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _StepNavRow(
          onBack: () => setState(() => _step = 2),
          nextLabel: 'حفظ المفتاح والبدء',
          onNext: _finishOnboarding,
        ),
      ],
    );
  }
}

class _StepHeaderBar extends StatelessWidget {
  const _StepHeaderBar({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < totalSteps; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4,
              decoration: BoxDecoration(
                color: i <= currentStep
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (i < totalSteps - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _ProviderOptionCard extends StatelessWidget {
  const _ProviderOptionCard({
    required this.selected,
    required this.icon,
    required this.color,
    required this.title,
    required this.bullets,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final Color color;
  final String title;
  final List<String> bullets;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? color
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SettingsIconBadge(icon: icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $b',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryOnboardingButton extends StatelessWidget {
  const _PrimaryOnboardingButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: onTap == null
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepNavRow extends StatelessWidget {
  const _StepNavRow({
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'التالي',
  });

  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: PressableScale(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'السابق',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _PrimaryOnboardingButton(label: nextLabel, onTap: onNext),
        ),
      ],
    );
  }
}

Future<bool?> showReflectionSummaryReviewSheet(
  BuildContext context,
  ReflectionSummary summary,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
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
                  icon: Icons.shield_outlined,
                  color: Color(0xFF007AFF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'مراجعة ملخص التأملات قبل المشاركة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'تم تلخيص تأملاتك محلياً بدون إرسال أي نص حرفي. هذا هو النص الذي سيصل للمساعد:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                summary.toReadableArabic(),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PressableScale(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(
                        child: Text(
                          'عدم المشاركة',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PressableScale(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(ctx).pop(true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(
                        child: Text(
                          'موافقة ومشاركة',
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
