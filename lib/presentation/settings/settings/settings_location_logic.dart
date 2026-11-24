part of '../settings_screen.dart';

mixin _SettingsLocationLogic on _SettingsLocationBase {
  Future<String> _refineLabel(Location loc, String query) async {
    try {
      final pm = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (pm.isEmpty) return query;
      final p = pm.first;
      final parts = <String>[
        if (p.locality != null && p.locality!.trim().isNotEmpty) p.locality!,
        if (p.subAdministrativeArea != null &&
            p.subAdministrativeArea!.trim().isNotEmpty)
          p.subAdministrativeArea!,
        if (p.country != null && p.country!.trim().isNotEmpty) p.country!,
      ];
      if (parts.isNotEmpty) return parts.join('، ');
    } catch (_) {}
    return query;
  }

  Future<void> _applyLocation(
      Location loc, AppSettings settings, String query) async {
    final label = await _refineLabel(loc, query);
    await ref.read(settingsProvider.notifier).updateSettings(
          settings.copyWith(
            prayerLocationMode: PrayerLocationMode.manual,
            manualLatitude: loc.latitude,
            manualLongitude: loc.longitude,
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

  Future<void> _runSearch(AppSettings settings) async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await locationFromAddress(q);
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
