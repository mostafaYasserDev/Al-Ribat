part of 'manual_location_dialog.dart';

Widget _buildLocationDialogContent({
  required BuildContext context,
  required BuildContext dialogContext,
  required TextEditingController controller,
  required bool loading,
  required List<Location> results,
  required Future<void> Function() onSearch,
  required void Function(Location) onPick,
}) {
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
                  Navigator.pop(dialogContext, (loc, city.name));
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
            controller: controller,
            decoration: InputDecoration(
              hintText: 'مثال: أسيوط، مصر أو باريس',
              suffixIcon: IconButton(
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                onPressed: loading ? null : onSearch,
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
          ..._buildResultTiles(results, onPick),
        ],
      ),
    ),
  );
}
