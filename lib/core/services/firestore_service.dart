import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/incident_model.dart';
import '../models/staff_model.dart';
import '../models/message_model.dart';
import '../constants/firestore_paths.dart';
import 'gemini_service.dart';

class FirestoreService {
  late final FirebaseFirestore _db;

  FirestoreService() {
    _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'sos1-1information',
    );
    
    // Enable persistence to support offline mode in hotel deadzones
    _db.settings = const Settings(
      persistenceEnabled: true,
    );
  }

  // Incident Operations
  Future<String> createIncident(IncidentModel incident) async {
    // Implicit Geofencing: Attach evacuation assembly point
    String assemblyPoint = "Lobby Exit A"; // Production default
    try {
      final configDoc = await _db.collection('hotelConfig').doc('general').get();
      if (configDoc.exists) {
        assemblyPoint = configDoc.data()?['assemblyPoint'] ?? assemblyPoint;
      }
    } catch (e) {
      debugPrint("Hotel Config fetch failed, using default: $e");
    }

    final updatedIncident = incident.copyWith(assemblyPoint: assemblyPoint);
    final data = updatedIncident.toMap();
    data['createdAt'] = FieldValue.serverTimestamp(); // High-integrity server stamp

    final docRef = await _db.collection(FirestorePaths.incidents).add(data);
    return docRef.id;
  }

  Stream<IncidentModel> streamIncident(String id) {
    return _db.collection(FirestorePaths.incidents).doc(id).snapshots().map(
      (snap) => IncidentModel.fromMap(snap.data() as Map<String, dynamic>, snap.id)
    );
  }

  Stream<List<IncidentModel>> streamActiveIncidents() {
    return _db.collection(FirestorePaths.incidents)
      .where('status', isNotEqualTo: 'resolved')
      .snapshots().map((snap) => snap.docs.map(
        (doc) => IncidentModel.fromMap(doc.data(), doc.id)
      ).toList());
  }

  Stream<IncidentModel?> getGuestActiveIncident(String roomNumber) {
    // We fetch incidents for this room that are NOT resolved
    // Using a simpler query first to avoid index requirements if possible, 
    // or at least making it more robust.
    return _db.collection(FirestorePaths.incidents)
      .where('roomNumber', isEqualTo: roomNumber)
      .snapshots().map((snap) {
        if (snap.docs.isEmpty) return null;
        
        try {
          // Filter out resolved ones and sort by time locally to avoid complex composite index requirements for now
          final activeDocs = snap.docs.where((doc) {
            final data = doc.data();
            return data['status'] != 'resolved';
          }).toList();

          if (activeDocs.isEmpty) return null;

          // Sort by createdAt descending
          activeDocs.sort((a, b) {
            final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          final doc = activeDocs.first;
          return IncidentModel.fromMap(doc.data(), doc.id);
        } catch (e) {
          debugPrint("Error in getGuestActiveIncident: $e");
          return null;
        }
      });
  }

  // Alias for backward compatibility
  Stream<List<IncidentModel>> getActiveIncidents() => streamActiveIncidents();
  
  Stream<List<IncidentModel>> streamAllIncidents() {
    return _db.collection(FirestorePaths.incidents)
      .orderBy('createdAt', descending: true)
      .snapshots().map((snap) => snap.docs.map(
        (doc) => IncidentModel.fromMap(doc.data(), doc.id)
      ).toList());
  }

  Stream<IncidentModel> getIncident(String id) => streamIncident(id);

  Future<void> updateIncident(String id, Map<String, dynamic> data) async {
    debugPrint("DEBUG: Updating incident $id with data: $data");
    
    // Inject server timestamps for critical state changes
    if (data['status'] == 'assigned' && data['assignedAt'] == null) {
      data['assignedAt'] = FieldValue.serverTimestamp();
    }
    if (data['status'] == 'resolved' && data['resolvedAt'] == null) {
      data['resolvedAt'] = FieldValue.serverTimestamp();
    }
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _db.collection(FirestorePaths.incidents).doc(id).set(data, SetOptions(merge: true));
    
    // Auto-generate report if resolved
    if (data['status'] == 'resolved') {
      generatePostIncidentReport(id);
    }
  }

  Future<void> removeIncidentMedia(String incidentId, String url) async {
    await _db.collection(FirestorePaths.incidents).doc(incidentId).update({
      'mediaUrls': FieldValue.arrayRemove([url])
    });
  }

  Future<void> generatePostIncidentReport(String id) async {
    try {
      final doc = await _db.collection(FirestorePaths.incidents).doc(id).get();
      if (!doc.exists) return;
      
      final data = doc.data()!;
      data['id'] = id; // Ensure ID is present for report generation
      
      // Get a professional report from Gemini
      final report = await GeminiService().generatePostIncidentReport(data);
      
      await _db.collection(FirestorePaths.incidents).doc(id).update({
        'postIncidentReport': report
      });
    } catch (e) {
      debugPrint("Report Error: $e");
    }
  }

  // Staff Operations
  Future<StaffModel?> getStaff(String id) async {
    final doc = await _db.collection(FirestorePaths.staff).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return StaffModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<List<StaffModel>> streamStaff() {
    return _db.collection(FirestorePaths.staff).snapshots().map(
      (snap) => snap.docs.map((doc) => StaffModel.fromMap(doc.data(), doc.id)).toList()
    );
  }

  // Messages
  Future<void> addMessage(String incidentId, MessageModel message) async {
    final data = message.toMap();
    data['createdAt'] = FieldValue.serverTimestamp(); // Ensure perfect chronological order
    await _db.collection(FirestorePaths.incidentMessages(incidentId)).add(data);
    
    // Auto-reopen logic: Detect distress in resolved incidents
    if (message.senderRole == 'guest') {
      final incidentDoc = await _db.collection(FirestorePaths.incidents).doc(incidentId).get();
      if (incidentDoc.exists) {
        final status = incidentDoc.get('status');
        if (status == 'resolved') {
          final text = message.text.toLowerCase();
          final distressKeywords = ['help', 'emergency', 'still', 'not safe', 'danger', 'please'];
          final hasDistress = distressKeywords.any((kw) => text.contains(kw));
          
          if (hasDistress) {
            await updateIncident(incidentId, {
              'status': 'assigned',
              'autoReopened': true,
              'autoReopenedAt': FieldValue.serverTimestamp(),
              'autoReopenReason': 'Guest sent distress message after resolution',
            });
            
            // Note: FCM should be sent here
            debugPrint("AUTO-REOPEN: Distress detected in $incidentId. Re-opening...");
          }
        }
      }
    }
  }

  Stream<List<MessageModel>> streamMessages(String incidentId) {
    return _db.collection(FirestorePaths.incidentMessages(incidentId))
      .orderBy('createdAt', descending: false)
      .snapshots().map((snap) => snap.docs.map(
        (doc) => MessageModel.fromMap(doc.data(), doc.id)
      ).toList());
  }

  // Alias for backward compatibility
  Stream<List<MessageModel>> getIncidentMessages(String id) => streamMessages(id);
  Future<void> sendMessage(String id, MessageModel msg) => addMessage(id, msg);
  Future<void> updateIncidentStatus(String id, String status) => updateIncident(id, {'status': status});

  Future<void> escalateOldIncidents() async {
    final threshold = DateTime.now().subtract(const Duration(seconds: 60));
    final snapshot = await _db
        .collection(FirestorePaths.incidents)
        .where('status', isEqualTo: 'pending')
        .get();

    final oldIncidents = snapshot.docs.where((doc) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      return createdAt != null && createdAt.isBefore(threshold);
    }).toList();

    if (oldIncidents.isEmpty) return;

    final batch = _db.batch();
    for (var doc in oldIncidents) {
      batch.update(doc.reference, {
        'escalationLevel': FieldValue.increment(1),
        'escalationCount': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // --- Staff Profile Extensions ---

  Future<void> saveStaffProfile(StaffModel staff) async {
    final data = staff.toMap();
    data['lastUpdated'] = FieldValue.serverTimestamp();
    await _db.collection(FirestorePaths.staff).doc(staff.id).set(data, SetOptions(merge: true));
  }

  Future<StaffModel?> getStaffProfile(String id) async {
    return getStaff(id);
  }

  Stream<List<StaffModel>> getOnDutyStaff() {
    return _db.collection(FirestorePaths.staff)
      .where('status', isNotEqualTo: 'offline')
      .snapshots().map((snap) => snap.docs.map(
        (doc) => StaffModel.fromMap(doc.data(), doc.id)
      ).toList());
  }
  Stream<StaffModel?> streamStaffMember(String staffId) {
    return _db.collection(FirestorePaths.staff).doc(staffId)
      .snapshots().map((doc) => doc.exists ? StaffModel.fromFirestore(doc) : null);
  }

  Future<void> updateStaffStatus(String staffId, String status) async {
    await _db.collection(FirestorePaths.staff).doc(staffId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<bool> pingStream() {
    return Stream.periodic(const Duration(seconds: 5), (_) => true);
  }
}

