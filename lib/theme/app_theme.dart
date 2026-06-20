import 'package:flutter/material.dart';

const _primary = Color(0xFF4CAF50);
const _secondary = Color(0xFFFF9800);

const _lightSurface = Color(0xFFFFFFFF);
const _lightBackground = Color(0xFFF7F8FA);
const _lightSurfaceVariant = Color(0xFFEEF0F3);
const _lightOnSurface = Color(0xFF222222);
const _lightOnSurfaceVariant = Color(0xFF6B7280);
const _lightOutline = Color(0xFFE5E7EB);

const _darkSurface = Color(0xFF202225);
const _darkBackground = Color(0xFF17181B);
const _darkSurfaceVariant = Color(0xFF2A2C30);
const _darkOnSurface = Color(0xFFE6E8EB);
const _darkOnSurfaceVariant = Color(0xFFA1A6AD);
const _darkOutline = Color(0xFF34383E);

ThemeData buildLightTheme({String? fontFamily}) {
  const colorScheme = ColorScheme.light(
    primary: _primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFC8E6C9),
    onPrimaryContainer: Color(0xFF1B5E20),
    secondary: _secondary,
    onSecondary: Colors.white,
    surface: _lightSurface,
    onSurface: _lightOnSurface,
    surfaceContainerHighest: _lightSurfaceVariant,
    onSurfaceVariant: _lightOnSurfaceVariant,
    error: Color(0xFFE53935),
    onError: Colors.white,
    outline: _lightOutline,
    surfaceTint: Colors.transparent,
  );

  return _buildBase(
    colorScheme: colorScheme,
    scaffoldColor: _lightBackground,
    surface: _lightSurface,
    surfaceVariant: _lightSurfaceVariant,
    outline: _lightOutline,
    onSurface: _lightOnSurface,
    onSurfaceVariant: _lightOnSurfaceVariant,
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
    surface: _darkSurface,
    onSurface: _darkOnSurface,
    surfaceContainerHighest: _darkSurfaceVariant,
    onSurfaceVariant: _darkOnSurfaceVariant,
    error: Color(0xFFEF5350),
    onError: Color(0xFF1A1A1A),
    outline: _darkOutline,
    surfaceTint: Colors.transparent,
  );

  return _buildBase(
    colorScheme: colorScheme,
    scaffoldColor: _darkBackground,
    surface: _darkSurface,
    surfaceVariant: _darkSurfaceVariant,
    outline: _darkOutline,
    onSurface: _darkOnSurface,
    onSurfaceVariant: _darkOnSurfaceVariant,
    fontFamily: fontFamily,
  );
}

ThemeData _buildBase({
  required ColorScheme colorScheme,
  required Color scaffoldColor,
  required Color surface,
  required Color surfaceVariant,
  required Color outline,
  required Color onSurface,
  required Color onSurfaceVariant,
  String? fontFamily,
}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldColor,
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 48,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: onSurface,
        fontFamily: fontFamily,
      ),
      shape: Border(bottom: BorderSide(color: outline, width: 0.5)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: surface,
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
    dividerTheme: DividerThemeData(color: outline, thickness: 0.5, space: 0.5),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface, fontFamily: fontFamily),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, fontFamily: fontFamily),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, fontFamily: fontFamily),
      bodyLarge: TextStyle(fontSize: 15, color: onSurface, fontFamily: fontFamily),
      bodyMedium: TextStyle(fontSize: 14, color: onSurface, fontFamily: fontFamily),
      bodySmall: TextStyle(fontSize: 12, color: onSurfaceVariant, fontFamily: fontFamily),
    ),
  );
}
