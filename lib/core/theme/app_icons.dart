import 'package:flutter/material.dart';

part 'app_icons_mapping.dart';

class AppIcons {
  const AppIcons._();

  static IconData getIconData(String? name) => _iconForName(name);

  static Color? parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final buffer = StringBuffer();
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        buffer.write('ff');
        buffer.write(clean);
      } else if (clean.length == 8) {
        buffer.write(clean);
      } else {
        return null;
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return null;
    }
  }
}
