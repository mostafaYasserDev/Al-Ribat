import 'package:flutter/material.dart';

class ReflectionColorOption {
  const ReflectionColorOption({
    required this.key,
    required this.label,
    required this.lightBg,
    required this.darkBg,
  });

  final String key;
  final String label;
  final Color lightBg;
  final Color darkBg;

  Color resolve(Brightness brightness) =>
      brightness == Brightness.light ? lightBg : darkBg;
}

/// Soft pastel note backgrounds inspired by Google Keep,
/// carefully tuned for both Light and Dark themes.
abstract final class ReflectionColors {
  static const List<ReflectionColorOption> palette = [
    ReflectionColorOption(
      key: 'sage',
      label: 'أخضر هادئ',
      lightBg: Color(0xFFE6F4EA),
      darkBg: Color(0xFF1B3126),
    ),
    ReflectionColorOption(
      key: 'sand',
      label: 'رملي دافئ',
      lightBg: Color(0xFFFEF7E0),
      darkBg: Color(0xFF332D1B),
    ),
    ReflectionColorOption(
      key: 'sky',
      label: 'سماوي',
      lightBg: Color(0xFFE8F0FE),
      darkBg: Color(0xFF1B2838),
    ),
    ReflectionColorOption(
      key: 'lavender',
      label: 'خزامى',
      lightBg: Color(0xFFF3E8FD),
      darkBg: Color(0xFF2B2038),
    ),
    ReflectionColorOption(
      key: 'rose',
      label: 'وردي ناعم',
      lightBg: Color(0xFFFCE8E6),
      darkBg: Color(0xFF362023),
    ),
    ReflectionColorOption(
      key: 'amber',
      label: 'عنبري',
      lightBg: Color(0xFFFFF0DB),
      darkBg: Color(0xFF35281A),
    ),
  ];

  static Color? resolveBackground(String? key, Brightness brightness) {
    if (key == null || key.isEmpty) return null;
    for (final opt in palette) {
      if (opt.key == key) return opt.resolve(brightness);
    }
    return null;
  }
}
