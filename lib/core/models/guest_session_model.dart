class GuestSessionModel {
  final String guestId;
  final String roomNumber;
  final String? floor;
  final String? wing;
  final String? hotelId;
  final String authMethod; // 'wifi', 'nfc', 'qr', 'manual'

  GuestSessionModel({
    required this.guestId,
    required this.roomNumber,
    this.floor,
    this.wing,
    this.hotelId,
    required this.authMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'guestId': guestId,
      'roomNumber': roomNumber,
      'floor': floor,
      'wing': wing,
      'hotelId': hotelId,
      'authMethod': authMethod,
    };
  }

  factory GuestSessionModel.fromMap(Map<String, dynamic> map) {
    return GuestSessionModel(
      guestId: map['guestId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      floor: map['floor'],
      wing: map['wing'],
      hotelId: map['hotelId'],
      authMethod: map['authMethod'] ?? 'manual',
    );
  }
}
