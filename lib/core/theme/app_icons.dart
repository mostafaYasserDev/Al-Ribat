import 'package:flutter/material.dart';

part 'app_icons_mapping.dart';

/// Metadata for a single selectable icon in the app catalog.
class AppIconEntry {
  const AppIconEntry({
    required this.key,
    required this.icon,
    required this.labelAr,
    required this.category,
    this.keywords = '',
  });

  final String key;
  final IconData icon;
  final String labelAr;
  final String category;
  final String keywords;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return labelAr.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        keywords.toLowerCase().contains(q) ||
        key.toLowerCase().contains(q);
  }
}

class AppIcons {
  const AppIcons._();

  static List<AppIconEntry> get catalog => _iconCatalog;

  static List<AppIconEntry> search(String query, {String? category}) {
    return _iconCatalog.where((entry) {
      if (category != null &&
          category.isNotEmpty &&
          entry.category != category) {
        return false;
      }
      return entry.matches(query);
    }).toList();
  }

  static AppIconEntry? entryFor(String? name) {
    if (name == null || name.isEmpty) return null;
    for (final entry in _iconCatalog) {
      if (entry.key == name) return entry;
    }
    return null;
  }

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
