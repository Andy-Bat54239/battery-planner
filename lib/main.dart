import 'package:flutter/material.dart';
import 'day_screen.dart';

void main() {
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
      home: const DayScreen(),
    );
  }
}