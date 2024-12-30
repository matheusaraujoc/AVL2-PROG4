// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  static const Duration themeDuration = Duration(milliseconds: 400);
  static const Curve themeCurve = Curves.easeInOutCubic;

  ThemeManager() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString(_themeKey);

      if (savedThemeMode != null) {
        _themeMode =
            savedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar tema: $e');
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (e) {
      print('Erro ao salvar tema: $e');
    }
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveThemeMode(_themeMode);
    notifyListeners();
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1E40AF),
      secondary: Color(0xFF3B82F6),
      secondaryContainer: Color(0xFFE5E7EB),
      onSecondaryContainer: Color(0xFF1F2937),
      surface: Colors.white,
      onSurface: Color(0xFF1F2937),
      surfaceContainerHighest: Color(0xFFF3F4F6),
      onSurfaceVariant: Color(0xFF4B5563),
      error: Color(0xFFDC2626),
      outline: Color(0xFFE5E7EB),
    ).copyWith(
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Color(0xFF1F2937),
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Color(0xFF1F2937),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(color: Color(0xFF374151)),
      bodyLarge: TextStyle(color: Color(0xFF4B5563)),
      bodyMedium: TextStyle(color: Color(0xFF4B5563)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF111827),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF60A5FA),
      primaryContainer: Color(0xFF1E40AF),
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: Color(0xFF93C5FD),
      secondaryContainer: Color(0xFF374151),
      onSecondaryContainer: Color(0xFFF3F4F6),
      surface: Color(0xFF1F2937),
      onSurface: Color(0xFFF9FAFB),
      surfaceContainerHighest: Color(0xFF374151),
      onSurfaceVariant: Color(0xFFE5E7EB),
      error: Color(0xFFFCA5A5),
      outline: Color(0xFF4B5563),
    ).copyWith(
      brightness: Brightness.dark,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: Color(0xFFF9FAFB),
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Color(0xFFF9FAFB),
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(color: Color(0xFFE5E7EB)),
      bodyLarge: TextStyle(color: Color(0xFFD1D5DB)),
      bodyMedium: TextStyle(color: Color(0xFFD1D5DB)),
    ),
  );
}
