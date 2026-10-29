import 'models.dart';

class DayResult{
  DayResult(this.battery, this.deathHour);

  final List<int?> battery;
  final int? deathHour;

  bool get survives => deathHour == null;
  int? get finalBattery => survives ? battery.last : null;
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