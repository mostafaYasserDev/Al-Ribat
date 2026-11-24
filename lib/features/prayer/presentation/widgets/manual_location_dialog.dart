import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import 'package:al_ribat/core/ui_feedback.dart';

class CityPreset {
  final String name;
  final double latitude;
  final double longitude;

  const CityPreset({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

const List<CityPreset> _kPopularCities = [
  CityPreset(name: 'مكة المكرمة', latitude: 21.4225, longitude: 39.8262),
  CityPreset(name: 'المدينة المنورة', latitude: 24.4672, longitude: 39.6111),
  CityPreset(name: 'القدس الشريف', latitude: 31.7683, longitude: 35.2137),
  CityPreset(name: 'القاهرة', latitude: 30.0444, longitude: 31.2357),
  CityPreset(name: 'الإسكندرية', latitude: 31.2001, longitude: 29.9187),
  CityPreset(name: 'الرياض', latitude: 24.7136, longitude: 46.6753),
  CityPreset(name: 'جدة', latitude: 21.5433, longitude: 39.1728),
  CityPreset(name: 'دبي', latitude: 25.2048, longitude: 55.2708),
  CityPreset(name: 'أبو ظبي', latitude: 24.4539, longitude: 54.3773),
  CityPreset(name: 'عمّان', latitude: 31.9454, longitude: 35.9284),
  CityPreset(name: 'الكويت', latitude: 29.3759, longitude: 47.9774),
  CityPreset(name: 'الدوحة', latitude: 25.2854, longitude: 51.5310),
  CityPreset(name: 'المنامة', latitude: 26.2285, longitude: 50.5860),
  CityPreset(name: 'مسقط', latitude: 23.5880, longitude: 58.3829),
  CityPreset(name: 'بغداد', latitude: 33.3152, longitude: 44.3661),
  CityPreset(name: 'دمشق', latitude: 33.5138, longitude: 36.2765),
  CityPreset(name: 'بيروت', latitude: 33.8938, longitude: 35.5018),
  CityPreset(name: 'طرابلس', latitude: 32.8872, longitude: 13.1913),
  CityPreset(name: 'تونس', latitude: 36.8065, longitude: 10.1815),
  CityPreset(name: 'الجزائر', latitude: 36.7538, longitude: 3.0588),
  CityPreset(name: 'الرباط', latitude: 34.0209, longitude: -6.8416),
  CityPreset(name: 'الخرطوم', latitude: 15.5007, longitude: 32.5599),
  CityPreset(name: 'إسطنبول', latitude: 41.0082, longitude: 28.9784),
];

Future<(Location, String)?> showManualLocationPickerDialog(
    BuildContext context) {
  return showDialog<(Location, String)>(
    context: context,
    builder: (ctx) => const _ManualLocationDialog(),
  );
}

class _ManualLocationDialog extends StatefulWidget {
  const _ManualLocationDialog();

  @override
  State<_ManualLocationDialog> createState() => _ManualLocationDialogState();
}

class _ManualLocationDialogState extends State<_ManualLocationDialog> {
  late final TextEditingController _controller;
  bool _loading = false;
  List<Location> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final found = await locationFromAddress(q);
      if (mounted) setState(() => _results = found.take(5).toList());
    } catch (e) {
      if (mounted) {
        setState(() => _results = const []);
        appError(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _resolveLocationLabel(
      Location location, String fallback) async {
    try {
      final marks =
          await placemarkFromCoordinates(location.latitude, location.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = <String>[
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!,
          if ((p.country ?? '').trim().isNotEmpty) p.country!,
        ];
        if (parts.isNotEmpty) return parts.join('، ');
      }
    } catch (_) {}
    return fallback;
  }

  List<Widget> _buildResultTiles(
    List<Location> results,
    void Function(Location) onPick,
  ) {
    if (results.isEmpty) return const [];
    return [
      const SizedBox(height: 10),
      ...results.asMap().entries.map(
            (e) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(
                '${e.value.latitude.toStringAsFixed(4)}, ${e.value.longitude.toStringAsFixed(4)}',
              ),
              subtitle: Text('نتيجة ${e.key + 1}'),
              onTap: () => onPick(e.value),
            ),
          ),
    ];
  }

  Widget _buildContent(BuildContext context) {
    return SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مدن شائعة للاختيار السريع:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _kPopularCities.map((city) {
                return ActionChip(
                  avatar: const Icon(Icons.location_city, size: 16),
                  label: Text(city.name),
                  onPressed: () {
                    final loc = Location(
                      latitude: city.latitude,
                      longitude: city.longitude,
                      timestamp: DateTime.now(),
                    );
                    Navigator.pop(context, (loc, city.name));
                  },
                );
              }).toList(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Text(
              'أو ابحث عن أي مدينة أو عنوان:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'مثال: أسيوط، مصر أو باريس',
                suffixIcon: IconButton(
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _loading ? null : _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            ..._buildResultTiles(_results, (loc) async {
              final navigator = Navigator.of(context);
              final label =
                  await _resolveLocationLabel(loc, _controller.text.trim());
              if (mounted) navigator.pop((loc, label));
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختيار الموقع'),
      content: _buildContent(context),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
