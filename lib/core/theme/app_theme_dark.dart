part of 'app_theme.dart';

ThemeData _buildDarkTheme() {
  const base = Color(0xFF0D1321);
  const accent = Color(0xFF76C893);
  const card = Color(0xFF111B2E);
  final baseText =
      ThemeData(brightness: Brightness.dark, useMaterial3: true).textTheme;
  final textTheme = GoogleFonts.tajawalTextTheme(baseText).copyWith(
    titleLarge: GoogleFonts.tajawal(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: GoogleFonts.tajawal(fontSize: 17, fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.tajawal(fontSize: 16, height: 1.45),
    bodyMedium: GoogleFonts.tajawal(fontSize: 15, height: 1.45),
    bodySmall: GoogleFonts.tajawal(fontSize: 13, height: 1.35),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: base,
      onSurface: Color(0xFFE8ECF0),
      primary: accent,
      onPrimary: Color(0xFF0D1321),
      secondary: Color(0xFFD8B26E),
      onSecondary: Color(0xFF1A1208),
      surfaceContainerHighest: Color(0xFF1E2A3D),
    ),
    scaffoldBackgroundColor: base,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF17243A),
      hintStyle: const TextStyle(
        color: Color(0x5CE6EDF3),
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
