import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String type;
  final String description;
  final String? translatedDescription;
  final String roomNumber;
  final String? floor;
  final String? wing;
  final String guestId;
  final String authMethod;
  final int severity;
  final String? suggestedTeam;
  final String? aiSummary;
  final String status;
  final String? assignedResponderId;
  final String? assignedResponderName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? assignedAt;
  final bool isOffline;
  final int escalationCount;
  final int escalationLevel;
  final List<String> escalationHistory;
  final String? postIncidentReport;
  final String? briefUrl;
  final List<String> mediaUrls;
  final bool isFalseAlarm;
  final String? falseAlarmReason;
  final DateTime? falseAlarmAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final bool autoConfirmed;
  final bool pinBypassed;
  final bool pinVerified;
  final String? closestStaffId;
  final double? lat;
  final double? lng;
  final bool callInitiated;
  final bool callAnswered;
  final String? resolvedBy;
  final String? resolvedByName;
  final String? resolvedByRole;
  final String? resolutionNotes;
  final Map<String, bool>? resolutionChecklist;
  final bool autoReopened;
  final DateTime? autoReopenedAt;
  final String? autoReopenReason;
  final String? assemblyPoint;
  final DateTime? triageStartedAt;
  final DateTime? triageCompletedAt;

  IncidentModel({
    required this.id,
    required this.type,
    required this.description,
    this.translatedDescription,
    required this.roomNumber,
    this.floor,
    this.wing,
    final String? guestId, // Changed to optional for copyWith flexibility if needed
    required this.authMethod,
    this.severity = 1,
    this.suggestedTeam,
    this.aiSummary,
    this.status = 'received',
    this.assignedResponderId,
    this.assignedResponderName,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedAt,
    this.isOffline = false,
    this.escalationCount = 0,
    this.escalationLevel = 0,
    this.escalationHistory = const [],
    this.postIncidentReport,
    this.briefUrl,
    this.mediaUrls = const [],
    this.isFalseAlarm = false,
    this.falseAlarmReason,
    this.falseAlarmAt,
    this.verifiedBy,
    this.verifiedAt,
    this.autoConfirmed = false,
    this.pinBypassed = false,
    this.pinVerified = false,
    this.closestStaffId,
    this.lat,
    this.lng,
    this.callInitiated = false,
    this.callAnswered = false,
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedByRole,
    this.resolutionNotes,
    this.resolutionChecklist,
    this.autoReopened = false,
    this.autoReopenedAt,
    this.autoReopenReason,
    this.assemblyPoint,
    this.triageStartedAt,
    this.triageCompletedAt,
    String? guestIdValue,
  }) : guestId = guestIdValue ?? '';


  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'translatedDescription': translatedDescription,
      'roomNumber': roomNumber,
      'floor': floor,
      'wing': wing,
      'guestId': guestId,
      'authMethod': authMethod,
      'severity': severity,
      'suggestedTeam': suggestedTeam,
      'aiSummary': aiSummary,
      'status': status,
      'assignedResponderId': assignedResponderId,
      'assignedResponderName': assignedResponderName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'isOffline': isOffline,
      'escalationCount': escalationCount,
      'escalationLevel': escalationLevel,
      'escalationHistory': escalationHistory,
      'postIncidentReport': postIncidentReport,
      'briefUrl': briefUrl,
      'mediaUrls': mediaUrls,
      'isFalseAlarm': isFalseAlarm,
      'falseAlarmReason': falseAlarmReason,
      'falseAlarmAt': falseAlarmAt != null ? Timestamp.fromDate(falseAlarmAt!) : null,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'autoConfirmed': autoConfirmed,
      'pinBypassed': pinBypassed,
      'pinVerified': pinVerified,
      'closestStaffId': closestStaffId,
      'lat': lat,
      'lng': lng,
      'callInitiated': callInitiated,
      'callAnswered': callAnswered,
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
      'resolvedByRole': resolvedByRole,
      'resolutionNotes': resolutionNotes,
      'resolutionChecklist': resolutionChecklist,
      'autoReopened': autoReopened,
      'autoReopenedAt': autoReopenedAt != null ? Timestamp.fromDate(autoReopenedAt!) : null,
      'autoReopenReason': autoReopenReason,
      'assemblyPoint': assemblyPoint,
      'triageStartedAt': triageStartedAt != null ? Timestamp.fromDate(triageStartedAt!) : null,
      'triageCompletedAt': triageCompletedAt != null ? Timestamp.fromDate(triageCompletedAt!) : null,
    };
  }

  Map<String, dynamic> toMeshMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'roomNumber': roomNumber,
      'guestId': guestId,
      'severity': severity,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map, String docId) {
    return IncidentModel(
      id: docId,
      type: map['type'] ?? 'other',
      description: map['description'] ?? '',
      translatedDescription: map['translatedDescription'],
      roomNumber: map['roomNumber'] ?? '',
      floor: map['floor'],
      wing: map['wing'],
      guestId: map['guestId'] ?? '',
      authMethod: map['authMethod'] ?? 'manual',
      severity: map['severity']?.toInt() ?? 1,
      suggestedTeam: map['suggestedTeam'],
      aiSummary: map['aiSummary'],
      status: map['status'] ?? 'received',
      assignedResponderId: map['assignedResponderId'],
      assignedResponderName: map['assignedResponderName'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate(),
      isOffline: map['isOffline'] ?? false,
      escalationCount: map['escalationCount']?.toInt() ?? 0,
      escalationLevel: map['escalationLevel']?.toInt() ?? 0,
      escalationHistory: List<String>.from(map['escalationHistory'] ?? []),
      postIncidentReport: map['postIncidentReport'],
      briefUrl: map['briefUrl'],
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      isFalseAlarm: map['isFalseAlarm'] ?? false,
      falseAlarmReason: map['falseAlarmReason'],
      falseAlarmAt: (map['falseAlarmAt'] as Timestamp?)?.toDate(),
      verifiedBy: map['verifiedBy'],
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
      autoConfirmed: map['autoConfirmed'] ?? false,
      pinBypassed: map['pinBypassed'] ?? false,
      pinVerified: map['pinVerified'] ?? false,
      closestStaffId: map['closestStaffId'],
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      callInitiated: map['callInitiated'] ?? false,
      callAnswered: map['callAnswered'] ?? false,
      resolvedBy: map['resolvedBy'],
      resolvedByName: map['resolvedByName'],
      resolvedByRole: map['resolvedByRole'],
      resolutionNotes: map['resolutionNotes'],
      resolutionChecklist: map['resolutionChecklist'] != null ? Map<String, bool>.from(map['resolutionChecklist']) : null,
      autoReopened: map['autoReopened'] ?? false,
      autoReopenedAt: (map['autoReopenedAt'] as Timestamp?)?.toDate(),
      autoReopenReason: map['autoReopenReason'],
      assemblyPoint: map['assemblyPoint'],
      triageStartedAt: (map['triageStartedAt'] as Timestamp?)?.toDate(),
      triageCompletedAt: (map['triageCompletedAt'] as Timestamp?)?.toDate(),
      guestIdValue: map['guestId'],
    );
  }

  factory IncidentModel.fromFirestore(DocumentSnapshot doc) {
    return IncidentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  IncidentModel copyWith({
    String? status,
    String? assignedResponderId,
    String? assignedResponderName,
    bool? isFalseAlarm,
    String? falseAlarmReason,
    double? lat,
    double? lng,
    bool? callInitiated,
    bool? callAnswered,
    bool? autoReopened,
    DateTime? autoReopenedAt,
    String? autoReopenReason,
    String? assemblyPoint,
    DateTime? triageStartedAt,
    DateTime? triageCompletedAt,
  }) {
    return IncidentModel(
      id: id,
      type: type,
      description: description,
      translatedDescription: translatedDescription,
      roomNumber: roomNumber,
      floor: floor,
      wing: wing,
      guestIdValue: guestId, // Pass to constructor param
      authMethod: authMethod,
      severity: severity,
      suggestedTeam: suggestedTeam,
      aiSummary: aiSummary,
      status: status ?? this.status,
      assignedResponderId: assignedResponderId ?? this.assignedResponderId,
      assignedResponderName: assignedResponderName ?? this.assignedResponderName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolvedAt: resolvedAt,
      assignedAt: assignedAt,
      isOffline: isOffline,
      escalationCount: escalationCount,
      escalationHistory: escalationHistory,
      postIncidentReport: postIncidentReport,
      briefUrl: briefUrl,
      mediaUrls: mediaUrls,
      isFalseAlarm: isFalseAlarm ?? this.isFalseAlarm,
      falseAlarmReason: falseAlarmReason ?? this.falseAlarmReason,
      falseAlarmAt: falseAlarmAt,
      verifiedBy: verifiedBy,
      verifiedAt: verifiedAt,
      autoConfirmed: autoConfirmed,
      pinBypassed: pinBypassed,
      pinVerified: pinVerified,
      closestStaffId: closestStaffId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      callInitiated: callInitiated ?? this.callInitiated,
      callAnswered: callAnswered ?? this.callAnswered,
      resolvedBy: resolvedBy,
      resolvedByName: resolvedByName,
      resolvedByRole: resolvedByRole,
      resolutionNotes: resolutionNotes,
      resolutionChecklist: resolutionChecklist,
      autoReopened: autoReopened ?? this.autoReopened,
      autoReopenedAt: autoReopenedAt ?? this.autoReopenedAt,
      autoReopenReason: autoReopenReason ?? this.autoReopenReason,
      assemblyPoint: assemblyPoint ?? this.assemblyPoint,
      triageStartedAt: triageStartedAt ?? this.triageStartedAt,
      triageCompletedAt: triageCompletedAt ?? this.triageCompletedAt,
    );
  }
}

