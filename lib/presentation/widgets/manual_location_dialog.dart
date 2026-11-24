import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import 'package:al_ribat/core/ui_feedback.dart';

part 'manual_location_dialog_cities.dart';
part 'manual_location_dialog_content.dart';
part 'manual_location_dialog_results.dart';

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختيار الموقع'),
      content: _buildLocationDialogContent(
        context: context,
        dialogContext: context,
        controller: _controller,
        loading: _loading,
        results: _results,
        onSearch: _search,
        onPick: (loc) async {
          final navigator = Navigator.of(context);
          final label =
              await _resolveLocationLabel(loc, _controller.text.trim());
          if (mounted) navigator.pop((loc, label));
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
