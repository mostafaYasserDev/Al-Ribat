import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import 'package:al_ribat/core/ui_feedback.dart';
import '../../data/location_search_service.dart';

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
  bool _searchedOnce = false;
  List<LocationSearchResult> _results = const [];

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
    setState(() {
      _loading = true;
      _searchedOnce = true;
    });
    try {
      final found = await LocationSearchService.searchPlaces(q);
      if (mounted) setState(() => _results = found);
    } catch (e) {
      if (mounted) {
        setState(() => _results = const []);
        appError(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Widget> _buildResultTiles(BuildContext context) {
    if (_results.isEmpty) {
      if (!_searchedOnce || _loading) return const [];
      return const [
        SizedBox(height: 12),
        Text(
          'لم يُعثر على نتائج مطابقة. جرّب كتابة اسم المدينة أو الدولة.',
          style: TextStyle(fontSize: 12.5, color: Colors.orange),
        ),
      ];
    }

    return [
      const SizedBox(height: 10),
      ..._results.map(
        (r) => ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(
            r.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            r.subtitle.isNotEmpty
                ? r.subtitle
                : '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
          ),
          onTap: () {
            final loc = Location(
              latitude: r.latitude,
              longitude: r.longitude,
              timestamp: DateTime.now(),
            );
            Navigator.pop(context, (loc, r.fullLabel));
          },
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
              children: LocationSearchService.popularCities.map((city) {
                return ActionChip(
                  avatar: const Icon(Icons.location_city, size: 16),
                  label: Text(city.name),
                  onPressed: () {
                    final loc = Location(
                      latitude: city.latitude,
                      longitude: city.longitude,
                      timestamp: DateTime.now(),
                    );
                    Navigator.pop(
                        context, (loc, '${city.name}، ${city.country}'));
                  },
                );
              }).toList(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Text(
              'أو ابحث عن أي مدينة أو حي:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'مثال: أسيوط، مصر أو Paris',
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
            ..._buildResultTiles(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تحديد الموقع يدوياً'),
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
