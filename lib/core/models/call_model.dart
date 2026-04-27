class CallModel {
  final String id;
  final String status; // 'initiating', 'ringing', 'connected', 'ended'
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final List<dynamic>? staffCandidates;
  final List<dynamic>? guestCandidates;
  final DateTime? startedAt;
  final DateTime? endedAt;

  CallModel({
    required this.id,
    this.status = 'initiating',
    this.offer,
    this.answer,
    this.staffCandidates,
    this.guestCandidates,
    this.startedAt,
    this.endedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'offer': offer,
      'answer': answer,
      'staffCandidates': staffCandidates,
      'guestCandidates': guestCandidates,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'endedAt': endedAt?.millisecondsSinceEpoch,
    };
  }

  factory CallModel.fromMap(Map<String, dynamic> map, String docId) {
    return CallModel(
      id: docId,
      status: map['status'] ?? 'initiating',
      offer: map['offer'] != null ? Map<String, dynamic>.from(map['offer']) : null,
      answer: map['answer'] != null ? Map<String, dynamic>.from(map['answer']) : null,
      staffCandidates: map['staffCandidates'] != null ? List<dynamic>.from(map['staffCandidates']) : null,
      guestCandidates: map['guestCandidates'] != null ? List<dynamic>.from(map['guestCandidates']) : null,
      startedAt: map['startedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt']) 
          : null,
      endedAt: map['endedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endedAt']) 
          : null,
    );
  }
}
