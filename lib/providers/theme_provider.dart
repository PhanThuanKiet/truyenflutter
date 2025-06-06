import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  defaultTheme,
  darkTheme,
  yellowTheme,
  purpleTheme,
}

class ThemeProvider extends ChangeNotifier {
  AppThemeMode _currentTheme = AppThemeMode.defaultTheme;

  AppThemeMode get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadThemeState();
  }

  Future<void> _loadThemeState() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _currentTheme = AppThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    _currentTheme = theme;
    await prefs.setInt('theme_mode', theme.index);
    notifyListeners();
  }

  ThemeData get theme {
    switch (_currentTheme) {
      case AppThemeMode.defaultTheme:
        return ThemeData.light();
      case AppThemeMode.darkTheme:
        return ThemeData.dark().copyWith(
          primaryColor: Colors.blueGrey[800],
          scaffoldBackgroundColor: Colors.grey[900],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
            titleLarge: TextStyle(color: Colors.white),
          ),
          cardTheme: CardTheme(
            color: Colors.grey[800],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey[700],
              foregroundColor: Colors.white,
            ),
          ),
        );
      case AppThemeMode.yellowTheme:
        return ThemeData.light().copyWith(
          scaffoldBackgroundColor: const Color(0xFFFFF3E0),
          primaryColor: Colors.amber[700],
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFF3E0),
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            titleLarge: TextStyle(color: Colors.black87),
          ),
          cardTheme: const CardTheme(
            color: Color(0xFFFFF8E1),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
          ),
        );
      case AppThemeMode.purpleTheme:
        return ThemeData.light().copyWith(
          scaffoldBackgroundColor: const Color(0xFFF3E5F5),
          primaryColor: Colors.purple[700],
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF3E5F5),
            foregroundColor: Colors.black87,
            elevation: 0,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black87),
            bodyMedium: TextStyle(color: Colors.black87),
            titleLarge: TextStyle(color: Colors.black87),
          ),
          cardTheme: const CardTheme(
            color: Color(0xFFE1BEE7),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
            ),
          ),
        );
    }
  }
} 