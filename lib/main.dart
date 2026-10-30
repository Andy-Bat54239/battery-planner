import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_gate.dart';
import 'theme_mode.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await loadThemeMode();
  runApp(const BatteryApp());
}

class BatteryApp extends StatelessWidget{
  const BatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Battery Planner',
          theme: ThemeData(colorSchemeSeed: Colors.green),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.green,
            brightness: Brightness.dark,
          ),
          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}
