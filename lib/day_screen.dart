import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'day_view.dart';
import 'edit_hour_screen.dart';
import 'models.dart';
import 'storage.dart';
import 'theme_mode.dart';

class DayScreen extends StatelessWidget{
  const DayScreen({super.key});

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

  Future<void> save(BuildContext context, List<HourPlan> plans) async {
    try {
      await saveHours(plans);
    } catch (e) {
      if(!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your change.')),
      );
    }
  }

  Future<void> confirmLogout(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your account';
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: Text('Signed in as $email'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if(sure == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Planner'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Light / dark mode',
            onPressed: () => toggleThemeMode(Theme.of(context).brightness),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => confirmLogout(context),
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

          return DayView(
            day: day,
            onEdit: (plan, before) => editHour(context, plan, before),
            onSave: (plans) => save(context, plans),
          );
        },
      ),
    );
  }
}
