import 'package:flutter/material.dart';

ThemeData buildLightTheme({String? fontFamily}) {
  const colorScheme = ColorScheme.light(
    primary: Color(0xFF4CAF50),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFC8E6C9),
    onPrimaryContainer: Color(0xFF1B5E20),
    secondary: Color(0xFFFF9800),
    onSecondary: Colors.white,
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF222222),
    surfaceContainerHighest: Color(0xFFEEF0F3),
    onSurfaceVariant: Color(0xFF6B7280),
    error: Color(0xFFE53935),
    onError: Colors.white,
    outline: Color(0xFFE5E7EB),
    surfaceTint: Colors.transparent,
  );

  return _buildBase(
    colorScheme: colorScheme,
    scaffoldColor: const Color(0xFFF7F8FA),
    fontFamily: fontFamily,
  );
}

ThemeData buildDarkTheme({String? fontFamily}) {
  const colorScheme = ColorScheme.dark(
    primary: Color(0xFF81C784),
    onPrimary: Color(0xFF1B5E20),
    primaryContainer: Color(0xFF2E7D32),
    onPrimaryContainer: Color(0xFFE8F5E9),
    secondary: Color(0xFFFFB74D),
    onSecondary: Color(0xFF3E2723),
    surface: Color(0xFF202225),
    onSurface: Color(0xFFE6E8EB),
    surfaceContainerHighest: Color(0xFF2A2C30),
    onSurfaceVariant: Color(0xFFA1A6AD),
    error: Color(0xFFEF5350),
    onError: Color(0xFF1A1A1A),
    outline: Color(0xFF34383E),
    surfaceTint: Colors.transparent,
  );

  return _buildBase(
    colorScheme: colorScheme,
    scaffoldColor: const Color(0xFF17181B),
    fontFamily: fontFamily,
  );
}

ThemeData _buildBase({
  required ColorScheme colorScheme,
  required Color scaffoldColor,
  String? fontFamily,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 48,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: fontFamily,
      ),
      shape: Border(bottom: BorderSide(color: colorScheme.outline, width: 0.5)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      ),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outline, thickness: 0.5, space: 0.5),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: fontFamily),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: fontFamily),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: fontFamily),
      bodyLarge: TextStyle(fontSize: 15, color: colorScheme.onSurface, fontFamily: fontFamily),
      bodyMedium: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontFamily: fontFamily),
      bodySmall: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontFamily: fontFamily),
    ),
  );
}
