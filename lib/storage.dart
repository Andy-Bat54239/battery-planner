import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

const _dayKey = 'day';

Future<void> saveDay(List<HourPlan> day) async {
  final prefs = await SharedPreferences.getInstance();
  final list = day.map((plan) => plan.toJson()).toList();
  await prefs.setString(_dayKey, jsonEncode(list));
}

Future<List<HourPlan>?> loadDay() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_dayKey);
  if (saved == null) return null;
  final list = jsonDecode(saved) as List;
  return list.map((x) => HourPlan.fromJson(x as Map<String, dynamic>)).toList();
}
