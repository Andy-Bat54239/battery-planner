import 'package:flutter/material.dart';
import 'models.dart';

class EditHourScreen extends StatefulWidget{
  const EditHourScreen({super.key, required this.hour, required this.plan});

  final int hour;
  final HourPlan plan;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in Activity.values)
                ChoiceChip(
                  label: Text('${a.label} (-${a.drain}%)'),
                  selected: a == activity,
                  onSelected: (_) => setState(() => activity = a),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Charging this hour'),
            subtitle: const Text('+20%'),
            value: charging,
            onChanged: (v) => setState(() => charging = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: () =>
                Navigator.pop(context, HourPlan(activity, charging: charging)),
              child: const Text('Save'),
          ),
        ],
      )
    );
  }
}