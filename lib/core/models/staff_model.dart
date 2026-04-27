import 'package:cloud_firestore/cloud_firestore.dart';

class StaffModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String status; // 'available', 'en_route', 'on_scene', 'offline'
  final String? fcmToken;
  final String? floor;
  final String? wing;
  final DateTime? lastSeen;
  final double? lat;
  final double? lng;
  final bool isAvailable;
  final String? phone;
  final String? currentIncidentId;

  StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'offline',
    this.fcmToken,
    this.floor,
    this.wing,
    this.lastSeen,
    this.lat,
    this.lng,
    this.isAvailable = false,
    this.phone,
    this.currentIncidentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'fcmToken': fcmToken,
      'floor': floor,
      'wing': wing,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'lat': lat,
      'lng': lng,
      'isAvailable': isAvailable,
      'phone': phone,
      'currentIncidentId': currentIncidentId,
    };
  }

  factory StaffModel.fromMap(Map<String, dynamic> map, String docId) {
    return StaffModel(
      id: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      status: map['status'] ?? 'offline',
      fcmToken: map['fcmToken'],
      floor: map['floor'],
      wing: map['wing'],
      lastSeen: map['lastSeen'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen']) 
          : null,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      isAvailable: map['isAvailable'] ?? false,
      phone: map['phone'],
      currentIncidentId: map['currentIncidentId'],
    );
  }

  factory StaffModel.fromFirestore(DocumentSnapshot doc) {
    return StaffModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
