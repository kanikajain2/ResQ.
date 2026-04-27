import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'guest', 'staff'
  final String text;
  final String? translatedText;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.translatedText,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'translatedText': translatedText,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderRole: map['senderRole'] ?? 'guest',
      text: map['text'] ?? '',
      translatedText: map['translatedText'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
