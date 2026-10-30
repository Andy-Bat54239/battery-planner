import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_gate.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BatteryApp());
}

class BatteryApp extends StatelessWidget{
  const BatteryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battery Planner',
      theme: ThemeData(colorSchemeSeed: Colors.green),
      home: const AuthGate(),
    );
  }
}
