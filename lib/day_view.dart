import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'activity_style.dart';
import 'models.dart';
import 'simulation.dart';
import 'weather_card.dart';

const double tileHeight = 64;

String clock(int hour) => '${hour.toString().padLeft(2, '0')}:00';

// A brush paints one change onto an hour: tap an hour, or hold and drag
class _Brush{
  const _Brush(this.label, this.icon, this.color, this.apply);

  final String label;
  final IconData icon;
  final Color color;
  final HourPlan Function(HourPlan) apply;
}

final _brushes = [
  for (final a in Activity.values)
    _Brush(a.label, a.icon, a.color, (p) => HourPlan(p.hour, a, charging: p.charging)),
  _Brush('Charge', Icons.bolt, Colors.amber, (p) => HourPlan(p.hour, p.activity, charging: true)),
  _Brush('Unplug', Icons.power_off, Colors.blueGrey, (p) => HourPlan(p.hour, p.activity)),
];

class DayView extends StatefulWidget{
  const DayView({
    super.key,
    required this.day,
    required this.onEdit,
    required this.onSave,
  });

  final List<HourPlan> day;
  final void Function(HourPlan plan, int before) onEdit;
  final void Function(List<HourPlan> plans) onSave;

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView>{
  final _scroll = ScrollController();
  int scrub = -1;
  _Brush? brush;
  int? _lastPainted;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void moveScrub(int index) {
    if(index == scrub) return;
    HapticFeedback.selectionClick();
    setState(() => scrub = index);
    if(!_scroll.hasClients) return;
    final target = (index * tileHeight).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void paint(int index) {
    final plan = widget.day[index];
    final next = brush!.apply(plan);
    if(next.activity == plan.activity && next.charging == plan.charging) return;
    HapticFeedback.lightImpact();
    widget.onSave([next]);
  }

  // Swipe right: toggle charging. Swipe left: set Idle.
  void swipe(HourPlan plan, DismissDirection direction) {
    HapticFeedback.lightImpact();
    if(direction == DismissDirection.startToEnd) {
      widget.onSave([HourPlan(plan.hour, plan.activity, charging: !plan.charging)]);
    } else {
      widget.onSave([HourPlan(plan.hour, Activity.idle, charging: plan.charging)]);
    }
  }

  void fix() {
    final changes = fixDay(widget.day);
    if(changes.isEmpty) return;
    final originals = [
      for (final change in changes)
        widget.day.firstWhere((plan) => plan.hour == change.hour).copy(),
    ];
    HapticFeedback.mediumImpact();
    widget.onSave(changes);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Added charging at ${changes.map((p) => clock(p.hour)).join(', ')}',
          ),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => widget.onSave(originals),
          ),
        ),
      );
  }

  int indexAt(Offset position) {
    final index = (position.dy + _scroll.offset) ~/ tileHeight;
    return index.clamp(0, widget.day.length - 1);
  }

  void paintAt(Offset position) {
    final index = indexAt(position);
    if(index == _lastPainted) return;
    _lastPainted = index;
    paint(index);
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final result = simulate(day);
    final chargingHours = day.where((plan) => plan.charging).length;
    final shown = (scrub < 0 || scrub >= day.length) ? day.length - 1 : scrub;
    final painting = brush != null;

    return Column(
      children: [
        _Banner(
          result: result,
          chargingHours: chargingHours,
          onFix: result.survives ? null : fix,
        ),
        _BatteryHero(
          level: result.battery[shown],
          plan: day[shown],
          index: shown,
          count: day.length,
          onScrub: moveScrub,
        ),
        _DayStrip(day: day, shown: shown, onScrub: moveScrub),
        const WeatherCard(),
        Expanded(
          child: GestureDetector(
            onLongPressStart: painting ? (d) => paintAt(d.localPosition) : null,
            onLongPressMoveUpdate:
                painting ? (d) => paintAt(d.localPosition) : null,
            onLongPressEnd: (_) => _lastPainted = null,
            child: ListView.builder(
              controller: _scroll,
              itemExtent: tileHeight,
              itemCount: day.length,
              itemBuilder: (context, index){
                final before = index == 0 ? 100 : (result.battery[index - 1] ?? 0);
                return _HourTile(
                  plan: day[index],
                  level: result.battery[index],
                  highlighted: index == shown,
                  swipeable: !painting,
                  onSwipe: (direction) => swipe(day[index], direction),
                  onTap: () => painting
                      ? paint(index)
                      : widget.onEdit(day[index], before),
                );
              },
            ),
          ),
        ),
        _BrushBar(
          selected: brush,
          onSelect: (b) => setState(() => brush = b),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget{
  const _Banner({
    required this.result,
    required this.chargingHours,
    required this.onFix,
  });

  final DayResult result;
  final int chargingHours;
  final void Function()? onFix;

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: background,
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(facts, style: TextStyle(color: foreground, fontSize: 12)),
          if(onFix != null)
            TextButton.icon(
              onPressed: onFix,
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Fix my day'),
              style: TextButton.styleFrom(
                foregroundColor: foreground,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

// A big battery that fills and drains as you slide through the day
class _BatteryHero extends StatelessWidget{
  const _BatteryHero({
    required this.level,
    required this.plan,
    required this.index,
    required this.count,
    required this.onScrub,
  });

  final int? level;
  final HourPlan plan;
  final int index;
  final int count;
  final void Function(int) onScrub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dead = level == null;
    final shown = level ?? 0;
    final color = shown < 20
        ? Colors.red
        : shown < 50
            ? Colors.amber
            : Colors.green;
    final caption = dead
        ? 'Dead by ${clock(plan.hour)}'
        : '${clock(plan.hour)} · ${plan.activity.label}'
            '${plan.charging ? ' · charging' : ''}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: shown / 100),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return Row(
                    children: [
                      Container(
                        width: 120,
                        height: 52,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: scheme.outline, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: value,
                                heightFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ),
                            if(plan.charging && !dead)
                              const Icon(Icons.bolt, size: 30, color: Colors.white),
                          ],
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 20,
                        decoration: BoxDecoration(
                          color: scheme.outline,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: shown.toDouble()),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return Text(
                        '${value.round()}%',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dead ? scheme.error : null,
                        ),
                      );
                    },
                  ),
                  Text(caption, style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
          if(count > 1)
            Slider(
              value: index.toDouble(),
              min: 0,
              max: (count - 1).toDouble(),
              divisions: count - 1,
              label: clock(plan.hour),
              onChanged: (v) => onScrub(v.round()),
            ),
        ],
      ),
    );
  }
}

class _HourTile extends StatelessWidget{
  const _HourTile({
    required this.plan,
    required this.level,
    required this.highlighted,
    required this.swipeable,
    required this.onSwipe,
    required this.onTap,
  });

  final HourPlan plan;
  final int? level;
  final bool highlighted;
  final bool swipeable;
  final void Function(DismissDirection) onSwipe;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dead = level == null;
    final low = !dead && level! < 20;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final tile = ListTile(
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      tileColor: highlighted ? scheme.primaryContainer.withValues(alpha: 0.5) : null,
      leading: Text(
        clock(plan.hour),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      title: Row(
        children: [
          Icon(
            plan.activity.icon,
            size: 18,
            color: dead ? scheme.outline : plan.activity.color,
          ),
          const SizedBox(width: 6),
          Text(
            plan.activity.label,
            style: TextStyle(color: dead ? scheme.outline : null),
          ),
          const SizedBox(width: 8),
          _Chip(
            text: '-${plan.activity.drain}%',
            color: dark ? Colors.red.shade300 : Colors.red.shade700,
          ),
          if(plan.charging) ...[
            const SizedBox(width: 4),
            _Chip(
              text: '+$chargeAmount%',
              color: dark ? Colors.amber.shade300 : Colors.amber.shade800,
            ),
            const SizedBox(width: 2),
            const Icon(Icons.bolt, size: 18, color: Colors.amber),
          ],
        ],
      ),
      subtitle: dead
        ? Text('Dead', style: TextStyle(color: scheme.outline))
        : Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: level! / 100),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: low ? Colors.red : Colors.green,
                );
              },
            ),
        ),
      trailing: dead
      ? null
      : TweenAnimationBuilder<double>(
          tween: Tween(end: level!.toDouble()),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return Text(
              '${value.round()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: low ? Colors.red : null,
              ),
            );
          },
        ),
    );

    return Dismissible(
      key: ValueKey(plan.hour),
      direction: swipeable ? DismissDirection.horizontal : DismissDirection.none,
      // the tile never leaves: the swipe only triggers the action
      confirmDismiss: (direction) async {
        onSwipe(direction);
        return false;
      },
      background: _SwipeBackground(
        color: Colors.amber,
        icon: Icons.bolt,
        text: plan.charging ? 'Unplug' : 'Charge',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        color: Colors.blueGrey,
        icon: Icons.bedtime_outlined,
        text: 'Set Idle',
        alignment: Alignment.centerRight,
      ),
      child: tile,
    );
  }
}

class _SwipeBackground extends StatelessWidget{
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.text,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final left = alignment == Alignment.centerLeft;
    final children = [Icon(icon), const SizedBox(width: 6), Text(text)];

    return Container(
      color: color.withValues(alpha: 0.35),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: left ? children : children.reversed.toList(),
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

class _BrushBar extends StatelessWidget{
  const _BrushBar({required this.selected, required this.onSelect});

  final _Brush? selected;
  final void Function(_Brush?) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                selected == null
                    ? 'Tap an hour to edit it, or pick a brush to paint'
                    : 'Tap an hour to paint it · hold and drag to paint several',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    selected: selected == null,
                    onSelected: (_) => onSelect(null),
                  ),
                  for (final b in _brushes) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(b.icon, size: 18, color: b.color),
                      label: Text(b.label),
                      selected: identical(selected, b),
                      onSelected: (_) => onSelect(b),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// The whole day in one bar: a colour for each activity, a bolt-coloured
// underline for charging hours. Tap a segment to jump to that hour.
class _DayStrip extends StatelessWidget{
  const _DayStrip({
    required this.day,
    required this.shown,
    required this.onScrub,
  });

  final List<HourPlan> day;
  final int shown;
  final void Function(int) onScrub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          for (var i = 0; i < day.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onScrub(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: day[i].activity.color,
                          borderRadius: BorderRadius.circular(3),
                          border: i == shown
                              ? Border.all(color: scheme.onSurface, width: 2)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: day[i].charging ? Colors.amber : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
