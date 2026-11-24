import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

part 'app_theme_dark.dart';
part 'app_theme_light.dart';

class AppTheme {
  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData get lightTheme => _buildLightTheme();
}
