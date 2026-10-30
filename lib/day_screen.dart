import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'activity_style.dart';
import 'edit_hour_screen.dart';
import 'models.dart';
import 'simulation.dart';
import 'storage.dart';
import 'weather.dart';

class DayScreen extends StatelessWidget{
  const DayScreen({super.key});

  String clock(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  Future<void> editHour(BuildContext context, HourPlan plan, int before) async {
    final result = await Navigator.push<HourPlan>(
      context,
      MaterialPageRoute(
        builder: (_) => EditHourScreen(
          hour: plan.hour,
          plan: plan.copy(),
          before: before,
        ),
      ),
    );

    if(result == null) return;
    try {
      await saveHour(result);
    } catch (e) {
      if(!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your change.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: myHours().orderBy('hour').snapshots(),
        builder: (context, snapshot) {
          if(snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load your plan.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if(!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final day = snapshot.data!.docs
              .map((doc) => HourPlan.fromMap(doc.data()))
              .toList();
          if(day.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your day is empty.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: addSampleDay,
                    child: const Text('Start with a sample day'),
                  ),
                ],
              ),
            );
          }

          final result = simulate(day);
          return Column(
            children: [
              _Banner(
                result: result,
                clock: clock,
                chargingHours: day.where((plan) => plan.charging).length,
              ),
              const _WeatherCard(),
              Expanded(
                child: ListView.builder(
                  itemCount: day.length,
                  itemBuilder: (context, index){
                    final before = index == 0 ? 100 : (result.battery[index - 1] ?? 0);
                    return _HourTile(
                      label: clock(day[index].hour),
                      plan: day[index],
                      level: result.battery[index],
                      onTap: () => editHour(context, day[index], before),
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget{
  const _Banner({
    required this.result,
    required this.clock,
    required this.chargingHours,
  });

  final DayResult result;
  final String Function(int) clock;
  final int chargingHours;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dies = !result.survives;
    final tight = !dies && result.finalBattery! < 20;

    final String text;
    final Color background;
    final Color foreground;
    if(dies) {
      text = '☠ Dies at ${clock(result.deathHour!)}';
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else if(tight) {
      text = 'Survives, but only ${result.finalBattery}% left';
      background = Colors.amber.shade100;
      foreground = Colors.brown.shade900;
    } else {
      text = 'Survives with ${result.finalBattery}% left';
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
    }
    final facts = 'Lowest ${result.lowest}% · '
        '$chargingHours charging ${chargingHours == 1 ? 'hour' : 'hours'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: background,
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(facts, style: TextStyle(color: foreground)),
        ],
      ),
    );
  }
}

IconData iconFor(int code) {
  if(code == 0) return Icons.wb_sunny;
  if(code <= 2) return Icons.wb_cloudy;
  if(code == 3) return Icons.cloud;
  if(code == 45 || code == 48) return Icons.foggy;
  if(code >= 95) return Icons.thunderstorm;
  if((code >= 71 && code <= 77) || code == 85 || code == 86) return Icons.ac_unit;
  if(code >= 51) return Icons.water_drop;
  return Icons.help_outline;
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Widget content;
    if(loading) {
      content = const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator()),
      );
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
          Icon(iconFor(w.code), size: 44, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kigali today', style: textTheme.labelMedium),
                Text(
                  '${w.temperature.round()}°C',
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(describe(w.code)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Detail(icon: Icons.water_drop_outlined, text: '${w.humidity}%'),
              const SizedBox(height: 6),
              _Detail(icon: Icons.air, text: '${w.wind.round()} km/h'),
            ],
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

class _Detail extends StatelessWidget{
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(text),
      ],
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
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Text(label, style: Theme.of(context).textTheme.titleMedium),
      title: Row(
        children: [
          Icon(
            plan.activity.icon,
            size: 18,
            color: dead ? scheme.outline : null,
          ),
          const SizedBox(width: 6),
          Text(
            plan.activity.label,
            style: TextStyle(color: dead ? scheme.outline : null),
          ),
          const SizedBox(width: 8),
          _Chip(text: '-${plan.activity.drain}%', color: Colors.red.shade700),
          if(plan.charging) ...[
            const SizedBox(width: 4),
            _Chip(text: '+$chargeAmount%', color: Colors.amber.shade800),
            const SizedBox(width: 2),
            const Icon(Icons.bolt, size: 18, color: Colors.amber),
          ],
        ],
      ),
      subtitle: dead
        ? Text('Dead', style: TextStyle(color: scheme.outline))
        : Padding(
            padding: const EdgeInsets.only(top: 4),
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

class _Chip extends StatelessWidget{
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
