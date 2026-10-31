enum Activity{
  video('Video', 12),
  games('Games', 15),
  chat('Chat', 5),
  music('Music', 6),
  idle('Idle', 2);

  const Activity(this.label, this.drain);

  final String label;
  final int drain;
}

const int firstHour = 7;
const int lastHour = 23;
const int chargeAmount = 20;

class HourPlan{
  HourPlan(this.hour, this.activity, {this.charging = false});

  final int hour;
  Activity activity;
  bool charging;

  HourPlan copy() => HourPlan(hour, activity, charging: charging);

  Map<String, dynamic> toMap() {
    return {'hour': hour, 'activity': activity.name, 'charging': charging};
  }

  factory HourPlan.fromMap(Map<String, dynamic> map) {
    return HourPlan(
      (map['hour'] as num).toInt(),
      Activity.values.byName(map['activity'] as String),
      charging: map['charging'] as bool,
    );
  }
}

List<HourPlan> sampleDay(){
  const activities = [
    Activity.idle, Activity.video, Activity.video, Activity.chat,
    Activity.games, Activity.video, Activity.chat, Activity.video,
    Activity.games, Activity.idle, Activity.video, Activity.games,
    Activity.chat, Activity.video, Activity.games, Activity.chat,
    Activity.idle,
  ];
  return [
    for (var i = 0; i < activities.length; i++)
      HourPlan(firstHour + i, activities[i]),
  ];
}
