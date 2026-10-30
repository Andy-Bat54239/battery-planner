import 'models.dart';

class DayResult{
  DayResult(this.battery, this.deathHour);

  final List<int?> battery;
  final int? deathHour;

  bool get survives => deathHour == null;
  int? get finalBattery => survives ? battery.last : null;
  int get lowest => battery.whereType<int>().fold(100, (a, b) => a < b ? a : b);
}

DayResult simulate(List<HourPlan> day, {int start = 100}) {
  var level = start;
  int? deathHour;
  final battery = <int?>[];

  for (var i = 0; i < day.length; i++) {
    if(deathHour != null){
      battery.add(null);
      continue;
    }

    final plan = day[i];
    level = level - plan.activity.drain + (plan.charging ? chargeAmount : 0);
    level = level.clamp(0, 100).toInt();
    battery.add(level);
    if (level == 0) deathHour = firstHour + i;
  }
  return DayResult(battery, deathHour);
}

// Adds charging where the battery dies, again and again, until the day survives.
// Returns only the hours that changed.
List<HourPlan> fixDay(List<HourPlan> day) {
  final fixed = [for (final plan in day) plan.copy()];

  while (true) {
    final result = simulate(fixed);
    if (result.survives) break;
    final index = result.deathHour! - firstHour;
    if (fixed[index].charging) break;
    fixed[index].charging = true;
  }

  return [
    for (var i = 0; i < day.length; i++)
      if (fixed[i].charging != day[i].charging) fixed[i],
  ];
}
