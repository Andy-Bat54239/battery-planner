import 'package:flutter/material.dart';
import 'activity_style.dart';
import 'models.dart';

class EditHourScreen extends StatefulWidget{
  const EditHourScreen({
    super.key,
    required this.hour,
    required this.plan,
    required this.before,
  });

  final int hour;
  final HourPlan plan;
  final int before;

  @override
  State<EditHourScreen> createState() => _EditHourScreenState();
}

class _EditHourScreenState extends State<EditHourScreen>{
  late Activity activity = widget.plan.activity;
  late bool charging = widget.plan.charging;

  @override
  Widget build(BuildContext context){
    final clock = '${widget.hour.toString().padLeft(2, '0')}:00';

    return Scaffold(
      appBar: AppBar(title: Text('Edit $clock')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in Activity.values)
                    SizedBox(
                      width: width,
                      child: _ActivityCard(
                        activity: a,
                        selected: a == activity,
                        onTap: () => setState(() => activity = a),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.bolt, color: Colors.amber),
            title: const Text('Charging this hour'),
            subtitle: const Text('+20%'),
            value: charging,
            onChanged: (v) => setState(() => charging = v),
          ),
          const SizedBox(height: 8),
          _Preview(before: widget.before, activity: activity, charging: charging),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              HourPlan(widget.hour, activity, charging: charging),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget{
  const _ActivityCard({
    required this.activity,
    required this.selected,
    required this.onTap,
  });

  final Activity activity;
  final bool selected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : null,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(activity.icon, size: 28, color: activity.color),
            const SizedBox(height: 6),
            Text(activity.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('-${activity.drain}%', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget{
  const _Preview({
    required this.before,
    required this.activity,
    required this.charging,
  });

  final int before;
  final Activity activity;
  final bool charging;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final after = (before - activity.drain + (charging ? chargeAmount : 0))
        .clamp(0, 100)
        .toInt();
    final alreadyDead = before == 0;
    final dies = !alreadyDead && after == 0;
    final low = after < 20;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: alreadyDead
            ? const Text('The battery is already dead before this hour.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Battery this hour', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    '$before%  →  $after%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: low ? scheme.error : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: after / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: low ? Colors.red : Colors.green,
                  ),
                  if(dies) ...[
                    const SizedBox(height: 8),
                    Text('☠ The battery dies this hour', style: TextStyle(color: scheme.error)),
                  ],
                ],
              ),
      ),
    );
  }
}
