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
  HourPlan(this.activity, {this.charging = false});

  Activity activity;
  bool charging;

  HourPlan copy() => HourPlan(activity, charging: charging);

  Map<String, dynamic> toJson() {
    return {'activity': activity.name, 'charging': charging};
  }

  factory HourPlan.fromJson(Map<String, dynamic> json) {
    return HourPlan(
      Activity.values.byName(json['activity'] as String),
      charging: json['charging'] as bool,
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
  return [for (final a in activities) HourPlan(a)];
}