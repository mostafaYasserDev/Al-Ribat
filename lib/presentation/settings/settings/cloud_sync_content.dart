part of '../settings_screen.dart';

extension _CloudSyncContent on _CloudSyncCardState {
  Widget _buildAccountTile(User? user, bool signedIn) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.cloud_outlined,
          color: Theme.of(context).colorScheme.primary),
      title: const Text('المزامنة السحابية (Google)'),
      subtitle: Text(
        signedIn
            ? 'مسجل الدخول: ${user?.email ?? user?.displayName ?? "حساب Google"}'
            : 'اختياري — لمزامنة بياناتك عبر Firebase',
      ),
    );
  }

  Widget _buildSignInButton() {
    return FilledButton.icon(
      onPressed: _busy || !AppStartup.isFirebaseReady
          ? null
          : () => _run(() async {
                await CloudSyncService.signInWithGoogle();
              }, 'تم تسجيل الدخول.'),
      icon: const Icon(Icons.login),
      label: const Text('تسجيل الدخول بـ Google'),
    );
  }

  List<Widget> _buildSignedInActions() {
    return [
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await CloudSyncService.uploadBackup();
                      }, 'تم رفع النسخة السحابية.'),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('رفع'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        await CloudSyncService.downloadBackup();
                        _invalidateAll();
                      }, 'تم استعادة البيانات من السحابة.'),
              icon: const Icon(Icons.cloud_download_outlined),
              label: const Text('استعادة'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        onPressed: _busy
            ? null
            : () => _run(() async {
                  await CloudSyncService.signOut();
                }, 'تم تسجيل الخروج.'),
        icon: const Icon(Icons.logout),
        label: const Text('تسجيل الخروج'),
      ),
    ];
  }
}
