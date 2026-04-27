import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FalseAlarmService {
  late final FirebaseFirestore _db;

  FalseAlarmService() {
    _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sos1-1information',
    );
  }

  Future<void> triggerVerification(String incidentId, String closestStaffId) async {
    await _db.collection('incidents').doc(incidentId).update({
      'closestStaffId': closestStaffId,
      'verificationRequested': true,
      'verificationRequestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markFalseAlarm(String incidentId, String reason) async {
    await _db.collection('incidents').doc(incidentId).update({
      'isFalseAlarm': true,
      'falseAlarmReason': reason,
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }
}
