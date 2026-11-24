part of 'manual_location_dialog.dart';

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

Future<String> _resolveLocationLabel(Location location, String fallback) async {
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
