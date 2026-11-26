part of '../templates_sheet.dart';

IconData _getIcon(String name) => _iconMap[name] ?? AppIcons.getIconData(name);

Color _getColor(String hex) {
  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}
