part of 'app_theme.dart';

ThemeData _buildLightTheme() {
  const surface = Color(0xFFF2F4F3);
  const card = Color(0xFFFFFFFF);
  const primary = Color(0xFF1F6F4A);
  final baseText =
      ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme;
  final textTheme = GoogleFonts.tajawalTextTheme(baseText)
      .apply(
        bodyColor: const Color(0xFF1A1F24),
        displayColor: const Color(0xFF1A1F24),
      )
      .copyWith(
        titleLarge: GoogleFonts.tajawal(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF142018),
        ),
        titleMedium: GoogleFonts.tajawal(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF142018),
        ),
        titleSmall: GoogleFonts.tajawal(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2C3530),
        ),
        bodyLarge: GoogleFonts.tajawal(
            fontSize: 16, height: 1.45, color: const Color(0xFF2C3530)),
        bodyMedium: GoogleFonts.tajawal(
            fontSize: 15, height: 1.45, color: const Color(0xFF3D4540)),
        bodySmall: GoogleFonts.tajawal(
            fontSize: 13, height: 1.35, color: const Color(0xFF5C6560)),
      );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      surface: surface,
      onSurface: Color(0xFF1A1F24),
      primary: primary,
      onPrimary: Colors.white,
      secondary: Color(0xFFB8893A),
      onSecondary: Color(0xFF1A1208),
      surfaceContainerHighest: Color(0xFFE3E8E5),
    ),
    scaffoldBackgroundColor: surface,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: Color(0xFF142018),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE8EEEA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
