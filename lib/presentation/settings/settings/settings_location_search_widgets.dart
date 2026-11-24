part of '../settings_screen.dart';

extension _SettingsLocationSearchWidgets on _SettingsScreenState {
  Widget _buildLocationSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'بحث (مثال: الرباط، المغرب)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLocationSearchButton(AppSettings settings) {
    return FilledButton.icon(
      onPressed: _searching ? null : () => _runSearch(settings),
      icon: _searching
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.search),
      label: Text(_searching ? 'جاري البحث…' : 'بحث عن نتائج'),
    );
  }

  List<Widget> _buildLocationResults(
      BuildContext context, AppSettings settings) {
    return [
      const SizedBox(height: 10),
      Text(
        'اختر النتيجة الأدق (عدة اقتراحات من الخادم):',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 6),
      ..._addressResults.asMap().entries.map((e) {
        final loc = e.value;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place_outlined),
          title: Text(
            '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
          ),
          subtitle: Text('اقتراح ${e.key + 1}'),
          onTap: () =>
              _applyLocation(loc, settings, _searchController.text.trim()),
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
