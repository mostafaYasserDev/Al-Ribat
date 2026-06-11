import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'developer_profile.dart';

/// شاشة «دعم المطوّر» — المحتوى القابل للتعديل في [DeveloperProfile].
class DeveloperSupportScreen extends StatelessWidget {
  const DeveloperSupportScreen({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يُضف الرابط بعد — حدّث الملف developer_profile.dart')),
      );
      return;
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرابط غير صالح')),
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط')),
        );
      }
    }
  }

  bool _looksLikeHttpUrl(String s) {
    final t = s.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  Future<void> _copy(BuildContext context, String label, String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد نص لـ $label في الإعدادات')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('نُسخ: $label')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دعم المطوّر')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      DeveloperProfile.photoAsset,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    DeveloperProfile.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DeveloperProfile.shortBio,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('ملاحظاتك تهمنا', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('الشكاوى والاقتراحات'),
              subtitle: const Text('أخبرنا برأيك أو اقترح ميزة جديدة'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openUrl(context, 'https://forms.gle/HSGemvnVdrfsNxWM8'),
            ),
          ),
          const SizedBox(height: 16),
          Text('الدعم المالي', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text(DeveloperProfile.vodafoneCashHint),
                  subtitle: Text(
                    DeveloperProfile.vodafoneCashValue.isEmpty
                        ? 'أضف الرابط في developer_profile.dart'
                        : DeveloperProfile.vodafoneCashValue,
                  ),
                  trailing: _looksLikeHttpUrl(DeveloperProfile.vodafoneCashValue)
                      ? const Icon(Icons.open_in_new)
                      : IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copy(
                            context,
                            'فودافون كاش',
                            DeveloperProfile.vodafoneCashValue,
                          ),
                        ),
                  onTap: _looksLikeHttpUrl(DeveloperProfile.vodafoneCashValue)
                      ? () => _openUrl(context, DeveloperProfile.vodafoneCashValue)
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text(DeveloperProfile.instapayHint),
                  subtitle: const Text('يفتح الرابط في المتصفح'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(context, DeveloperProfile.instapayUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text(DeveloperProfile.paypalHint),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(context, DeveloperProfile.paypalUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('التواصل والمجتمع', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('إنستغرام'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openUrl(context, DeveloperProfile.instagramUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('يوتيوب'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openUrl(context, DeveloperProfile.youtubeUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.music_note),
                  title: const Text('تيك توك'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openUrl(context, DeveloperProfile.tiktokUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.groups),
                  title: const Text('فيسبوك'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openUrl(context, DeveloperProfile.facebookUrl),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.send),
                  title: const Text('تيليجرام'),
                  subtitle: const Text('القناة أو الحساب الشخصي'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openUrl(context, DeveloperProfile.telegramUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
