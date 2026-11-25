part of '../settings_screen.dart';

extension _SettingsLocationSearchWidgets on _SettingsScreenState {
  Widget _buildLocationSearchField(AppSettings settings) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _runSearch(settings),
      decoration: const InputDecoration(
        labelText: 'بحث عن مدينة أو حي (مثال: أسيوط، مصر)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLocationSearchButton(AppSettings settings) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _searching ? null : () => _runSearch(settings),
          icon: _searching
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(_searching ? 'جاري البحث…' : 'بحث عن نتائج'),
        ),
        OutlinedButton.icon(
          onPressed: () => _pickFromPopularDialog(settings),
          icon: const Icon(Icons.location_city_rounded, size: 18),
          label: const Text('مدن شائعة'),
        ),
      ],
    );
  }

  List<Widget> _buildLocationResults(
      BuildContext context, AppSettings settings) {
    return [
      const SizedBox(height: 10),
      Text(
        'اختر المدينة المناسبة:',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 6),
      ..._addressResults.map((result) {
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(
            result.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            result.subtitle.isNotEmpty
                ? result.subtitle
                : '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
          ),
          onTap: () => _applyLocationResult(result, settings),
        );
      }),
    ];
  }

  Widget _buildSelectedLocation(BuildContext context, AppSettings settings) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        'المختار: ${settings.manualLocationLabel}\n'
        '${settings.manualLatitude?.toStringAsFixed(4)}, '
        '${settings.manualLongitude?.toStringAsFixed(4)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
