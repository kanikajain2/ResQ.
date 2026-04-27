import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/incident_model.dart';
import '../models/staff_model.dart';
import '../constants/firestore_paths.dart';

class AssignmentService {
  late final FirebaseFirestore _db;

  AssignmentService() {
    _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sos1-1information',
    );
  }

  /// Automatically assigns the nearest available staff to an incident.
  /// Uses a transaction to ensure Point 7 (Multi-device sync & conflict handling).
  Future<String?> autoAssignStaff(IncidentModel incident, double incidentLat, double incidentLng) async {
    return _db.runTransaction<String?>((transaction) async {
      // 1. Get available staff for the suggested team
      final staffQuery = _db.collection(FirestorePaths.staff)
          .where('role', isEqualTo: incident.suggestedTeam)
          .where('isAvailable', isEqualTo: true);
      
      final staffSnapshot = await staffQuery.get();
      if (staffSnapshot.docs.isEmpty) return null;

      StaffModel? closestStaff;
      double minDistance = double.infinity;

      for (var doc in staffSnapshot.docs) {
        final staff = StaffModel.fromFirestore(doc);
        if (staff.lat != null && staff.lng != null) {
          double distance = Geolocator.distanceBetween(
            incidentLat, 
            incidentLng, 
            staff.lat!, 
            staff.lng!
          );
          
          if (distance < minDistance) {
            minDistance = distance;
            closestStaff = staff;
          }
        }
      }

      // If no staff with location found, pick the first available one
      closestStaff ??= StaffModel.fromFirestore(staffSnapshot.docs.first);

      // 2. Lock the incident and staff (Conflict Handling)
      final incidentRef = _db.collection(FirestorePaths.incidents).doc(incident.id);
      final staffRef = _db.collection(FirestorePaths.staff).doc(closestStaff.id);

      final incidentDoc = await transaction.get(incidentRef);
      if (incidentDoc.data()?['assignedResponderId'] != null) {
        // Already assigned by another process
        return incidentDoc.data()?['assignedResponderId'];
      }

      // 3. Perform atomic update
      transaction.update(incidentRef, {
        'assignedResponderId': closestStaff.id,
        'status': 'assigned',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      transaction.update(staffRef, {
        'isAvailable': false,
        'currentIncidentId': incident.id,
      });

      return closestStaff.id;
    });
  }

  /// Finds the nearest available staff member to an incident location.
  Future<String?> findClosestStaff(String type, double lat, double lng) async {
    final staffQuery = _db.collection(FirestorePaths.staff)
        .where('isAvailable', isEqualTo: true);
    
    final staffSnapshot = await staffQuery.get();
    if (staffSnapshot.docs.isEmpty) return null;

    StaffModel? closestStaff;
    double minDistance = double.infinity;

    for (var doc in staffSnapshot.docs) {
      final staff = StaffModel.fromFirestore(doc);
      if (staff.lat != null && staff.lng != null) {
        double distance = Geolocator.distanceBetween(lat, lng, staff.lat!, staff.lng!);
        if (distance < minDistance) {
          minDistance = distance;
          closestStaff = staff;
        }
      }
    }

    return closestStaff?.id ?? staffSnapshot.docs.first.id;
  }

  /// Checks if the provided staffId matches the incident's closestStaffId
  Future<bool> isClosestStaff(IncidentModel incident, String staffId) async {
    final doc = await _db.collection(FirestorePaths.incidents).doc(incident.id).get();
    return doc.data()?['closestStaffId'] == staffId;
  }

  /// Calculates incident priority based on severity and escalation Level (Point 4)
  int calculatePriority(IncidentModel incident) {
    int priority = incident.severity * 10;
    priority += incident.escalationLevel * 5;
    return priority;
  }
}
