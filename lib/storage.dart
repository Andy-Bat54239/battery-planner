import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';

// The signed-in user's plan: users/{uid}/hours
CollectionReference<Map<String, dynamic>> myHours() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('hours');
}

// The hour is the document id, so saving an hour twice rewrites it
Future<void> saveHour(HourPlan plan) {
  return myHours().doc('${plan.hour}').set(plan.toMap());
}

// Several hours at once: all of them are saved, or none
Future<void> saveHours(List<HourPlan> plans) async {
  final batch = FirebaseFirestore.instance.batch();
  for (final plan in plans) {
    batch.set(myHours().doc('${plan.hour}'), plan.toMap());
  }
  await batch.commit();
}

// Sample data, written once when a new account is created
Future<void> addSampleDay() async {
  final batch = FirebaseFirestore.instance.batch();
  for (final plan in sampleDay()) {
    batch.set(myHours().doc('${plan.hour}'), plan.toMap());
  }
  await batch.commit();
}

// Delete every hour of the signed-in user's plan, all or none
Future<void> clearDay() async {
  final snapshot = await myHours().get();
  final batch = FirebaseFirestore.instance.batch();
  for (final doc in snapshot.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit();
}
