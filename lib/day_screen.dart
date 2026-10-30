import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'edit_hour_screen.dart';
import 'models.dart';
import 'simulation.dart';
import 'storage.dart';
import 'weather.dart';

class DayScreen extends StatefulWidget{
  const DayScreen({super.key});

  @override
  State<DayScreen> createState () => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<HourPlan> day = sampleDay();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final saved = await loadDay();
    if(!mounted || saved == null) return;
    setState(() => day = saved);
  }

  String clock(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  Future<void> editHour(int index) async {
    final result = await Navigator.push<HourPlan>(
      context,
      MaterialPageRoute(
        builder: (_) => EditHourScreen(
          hour: firstHour + index,
          plan: day[index].copy(),
        ),
      ),
    );

    if(!mounted || result == null) return;
    setState(() => day[index] = result);
    await saveDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final result = simulate(day);

    return Scaffold(
      appBar: AppBar(title: const Text('Battery Planner')),
      body: Column(
        children: [
          _Banner(result: result, clock: clock),
          const _WeatherCard(),
          Expanded(
            child: ListView.builder(
              itemCount: day.length,
              itemBuilder: (context, index){
                return _HourTile(
                  label: clock(firstHour + index),
                  plan: day[index],
                  level: result.battery[index],
                  onTap: () => editHour(index),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget{
  const _Banner({required this.result, required this.clock});

  final DayResult result;
  final String Function(int) clock;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dies = !result.survives;
    final text = dies ? '☠ Dies at ${clock(result.deathHour!)}' : 'Survives with ${result.finalBattery}% left';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: dies ? scheme.errorContainer : scheme.primaryContainer,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: dies ? scheme.onErrorContainer : scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _WeatherCard extends StatefulWidget{
  const _WeatherCard();

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard>{
  Weather? weather;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await fetchWeather();
      if(!mounted) return;
      setState(() {
        weather = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      if(!mounted) return;
      setState(() {
        loading = false;
        error = 'Could not load the weather. Check your internet connection.';
      });
    }
  }

  void retry() {
    setState(() {
      loading = true;
      error = null;
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if(loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if(error != null) {
      content = Row(
        children: [
          const Icon(Icons.wifi_off),
          const SizedBox(width: 12),
          Expanded(child: Text(error!)),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ],
      );
    } else {
      final w = weather!;
      content = Row(
        children: [
          const Icon(Icons.wb_sunny_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kigali today: ${w.temperature.round()}°C, ${describe(w.code)}'
              ' · ${w.humidity}% humidity · ${w.wind.round()} km/h wind',
            ),
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: content,
      ),
    );
  }
}

class _HourTile extends StatelessWidget{
  const _HourTile({
    required this.label,
    required this.plan,
    required this.level,
    required this.onTap,
  });

  final String label;
  final HourPlan plan;
  final int? level;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dead = level == null;
    final low = !dead && level! < 20;

    return ListTile(
      onTap: onTap,
      leading: Text(label, style: Theme.of(context).textTheme.titleMedium),
      title: Row(
        children: [
          Text(
            plan.activity.label,
            style: TextStyle(color: dead ? scheme.outline : null),
          ),
          if(plan.charging) ...[
            const SizedBox(width: 8),
            const Icon(Icons.bolt, size: 18, color: Colors.amber),
          ],
        ],
      ),
      subtitle: dead
        ? Text('Dead', style: TextStyle(color: scheme.outline))
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(
              value: level! / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: low ? Colors.red : Colors.green,
            ),
        ),
      trailing: dead
      ? null
      : Text(
          '$level%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: low ? Colors.red : null,
          ),
      ),
    );
  }
}