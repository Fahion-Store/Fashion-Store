import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider({bool initialDarkMode = false}) {
    _isDarkMode = initialDarkMode;
    AppColors.isDarkMode = initialDarkMode;
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    AppColors.isDarkMode = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
}
