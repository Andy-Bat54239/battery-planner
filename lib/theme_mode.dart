import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'theme';

// The app listens to this: changing it restyles every screen
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_themeKey);
  if(saved == 'light') themeMode.value = ThemeMode.light;
  if(saved == 'dark') themeMode.value = ThemeMode.dark;
}

// Switch to the opposite of what is on screen now
Future<void> toggleThemeMode(Brightness current) async {
  final next = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  themeMode.value = next;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeKey, next.name);
}
