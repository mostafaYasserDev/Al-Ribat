part of '../settings_screen.dart';

extension _SettingsAboutCards on _SettingsScreenState {
  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.info_outline,
            color: Theme.of(context).colorScheme.primary),
        title: const Text('عن التطبيق'),
        subtitle: const Text('فكرة التطبيق وسياسة الخصوصية'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const Directionality(
                textDirection: TextDirection.rtl,
                child: AboutAppScreen(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppLockCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.lock_outline,
            color: Theme.of(context).colorScheme.primary),
        title: const Text('قفل التطبيق برمز مرور'),
        subtitle: const Text('حماية بياناتك برمز مرور مكون من 4 أرقام'),
        trailing: const Icon(Icons.chevron_left),
        onTap: () {
          HapticFeedback.lightImpact();
          _showAppLockDialog(context);
        },
      ),
    );
  }
}
