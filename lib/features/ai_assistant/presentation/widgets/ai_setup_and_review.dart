import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/widgets/settings_ui_components.dart';
import '../../application/ai_providers.dart';
import '../../domain/ai_context_snapshot.dart';
import '../../domain/ai_provider_config.dart';
import '../ai_settings_page.dart';

class AiSetupView extends ConsumerStatefulWidget {
  const AiSetupView({super.key});

  @override
  ConsumerState<AiSetupView> createState() => _AiSetupViewState();
}

class _AiSetupViewState extends ConsumerState<AiSetupView> {
  final _keyController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
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
          Container(
            padding: const EdgeInsets.all(18),
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
                  size: 46,
                  iconSize: 24,
                ),
                const SizedBox(height: 12),
                Text(
                  'مرحباً بك في RibatAI',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'مساعدك الشخصي لتنظيم المهام حول الصلوات، اكتشاف تعارضات الوقت، ومتابعة أهدافك بخصوصية تامة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SettingsGroupCard(
            dividerIndent: 16,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'الإعداد السريع (سحابي — Groq مجاني)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'أدخل مفتاح Groq المجاني الخاص بك للبدء فوراً. لا تدرب Groq على بياناتك، ويمكنك التحكم بصلاحية كل قسم من الإعدادات.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.45,
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keyController,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
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
                    const SizedBox(height: 12),
                    PressableScale(
                      onTap: () async {
                        final key = _keyController.text.trim();
                        if (key.isEmpty) return;
                        HapticFeedback.lightImpact();
                        final current = ref.read(aiConfigProvider);
                        await ref.read(aiConfigProvider.notifier).updateConfig(
                              current.copyWith(
                                type: AiProviderType.groqCloud,
                                groqApiKey: key,
                                hasCompletedOnboarding: true,
                              ),
                            );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'حفظ المفتاح والبدء',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SettingsNavTile(
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF007AFF),
                title: 'خيارات المزوِّد والصلاحيات الكاملة',
                subtitle:
                    'مقارنة السحابي والمحلي، طريقة الحصول على المفتاح، والصلاحيات',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AiSettingsPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
