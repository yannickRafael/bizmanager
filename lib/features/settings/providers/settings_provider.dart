import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide settings (currency, language, theme).
class SettingsProvider extends ChangeNotifier {
  String _currencySymbol = '\$';
  String _language = 'pt';
  ThemeMode _themeMode = ThemeMode.system;

  String get currencySymbol => _currencySymbol;
  String get language => _language;
  ThemeMode get themeMode => _themeMode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString('currency_symbol') ?? '\$';
    _language = prefs.getString('language') ?? 'pt';
    final themeName = prefs.getString('theme_mode') ?? 'system';
    _themeMode = switch (themeName) {
      'light' => ThemeMode.light,
      'dark'  => ThemeMode.dark,
      _       => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    _currencySymbol = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_symbol', symbol);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }
}
