part of '../settings_screen.dart';

abstract class _SettingsLocationBase extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;
  List<Location> _addressResults = const [];
}

class _SettingsScreenState extends _SettingsLocationBase
    with _SettingsLocationLogic {
  final _manualSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.openManualLocationCard) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        final ctx = _manualSectionKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.05,
          duration: const Duration(milliseconds: 400),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAboutCard(context),
          _buildAppLockCard(context),
          const _CloudSyncCard(),
          _buildBackupExportCard(context),
          _buildBackupImportCard(context),
          _buildNotificationsCard(context, settings),
          _buildAlarmPermissionCard(context),
          _buildFocusModeCard(context, settings),
          _buildFocusLeadCard(context, settings),
          _buildPrayerSlotInfoCard(context, settings),
          _buildPrayerSlotDurationCard(context, settings),
          _buildLocationCard(context, settings),
          _buildPrayerMethodCard(context, settings),
          _buildAppearanceCard(context, settings),
        ],
      ),
    );
  }
}
