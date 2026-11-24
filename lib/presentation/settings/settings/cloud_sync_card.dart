part of '../settings_screen.dart';

class _CloudSyncCard extends ConsumerStatefulWidget {
  const _CloudSyncCard();

  @override
  ConsumerState<_CloudSyncCard> createState() => _CloudSyncCardState();
}

class _CloudSyncCardState extends ConsumerState<_CloudSyncCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) appSnack(context, successMsg);
    } catch (e) {
      if (mounted) appError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _invalidateAll() {
    ref.invalidate(settingsProvider);
    ref.invalidate(activitiesProvider);
    ref.invalidate(workSessionsProvider);
    ref.invalidate(reflectionsProvider);
    ref.invalidate(prayerScheduleProvider);
    ref.invalidate(streakProvider);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: CloudSyncService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final signedIn = user != null;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAccountTile(user, signedIn),
                if (!AppStartup.isFirebaseReady)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'المزامنة السحابية غير متاحة على هذا الجهاز. بياناتك محفوظة محلياً.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (!signedIn)
                  _buildSignInButton()
                else
                  ..._buildSignedInActions(),
              ],
            ),
          ),
        );
      },
    );
  }
}
