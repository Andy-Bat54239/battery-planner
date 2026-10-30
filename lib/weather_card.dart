import 'package:flutter/material.dart';
import 'weather.dart';

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

// Two colours for the card's background, chosen by the sky
List<Color> tintFor(int code) {
  if(code == 0) return [Colors.amber, Colors.orange];
  if(code <= 2) return [Colors.amber, Colors.lightBlue];
  if(code == 3) return [Colors.blueGrey, Colors.grey];
  if(code == 45 || code == 48) return [Colors.grey, Colors.blueGrey];
  if(code >= 95) return [Colors.deepPurple, Colors.blueGrey];
  if((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return [Colors.lightBlue, Colors.cyan];
  }
  if(code >= 51) return [Colors.blue, Colors.indigo];
  return [Colors.grey, Colors.blueGrey];
}

class WeatherCard extends StatefulWidget{
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard>{
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

    final tint = weather == null ? null : tintFor(weather!.code);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: tint == null
            ? null
            : BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tint[0].withValues(alpha: 0.28),
                    tint[1].withValues(alpha: 0.12),
                  ],
                ),
              ),
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
