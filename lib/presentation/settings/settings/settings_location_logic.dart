part of '../settings_screen.dart';

mixin _SettingsLocationLogic on _SettingsLocationBase {
  Future<void> _applyLocationResult(
    LocationSearchResult result,
    AppSettings settings,
  ) async {
    final label = result.fullLabel;
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(
            prayerLocationMode: PrayerLocationMode.manual,
            manualLatitude: result.latitude,
            manualLongitude: result.longitude,
            manualLocationLabel: label,
          ),
        );
    if (mounted) {
      setState(() => _addressResults = const []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم ضبط الموقع: $label')),
      );
    }
  }

  Future<void> _pickFromPopularDialog(AppSettings settings) async {
    final picked = await showManualLocationPickerDialog(context);
    if (picked == null || !mounted) return;
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(
            prayerLocationMode: PrayerLocationMode.manual,
            manualLatitude: picked.$1.latitude,
            manualLongitude: picked.$1.longitude,
            manualLocationLabel: picked.$2,
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم ضبط الموقع: ${picked.$2}')),
      );
    }
  }

  Future<void> _runSearch(AppSettings settings) async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await LocationSearchService.searchPlaces(q);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _addressResults = const []);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('لم يُعثر على موقع. جرّب مدينة، حي، أو دولة.')),
        );
        return;
      }
      setState(() => _addressResults = results);
    } catch (e) {
      if (mounted) {
        setState(() => _addressResults = const []);
        appError(context, e, fallback: 'تعذر البحث عن الموقع. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }
}
