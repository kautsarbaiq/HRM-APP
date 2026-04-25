import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0F172A),
      secondary: Color(0xFF0F172A),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFE2E8F0),
    ),
    useMaterial3: true,
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF020617),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF06B6D4),
      secondary: Color(0xFF8B5CF6),
      surface: Color(0xFF0F172A),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF334155),
    ),
    useMaterial3: true,
  );
}
