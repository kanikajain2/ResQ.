class WifiService {
  Future<String?> getCurrentSSID() async {
    // Stub implementation
    return 'ResQ-F3-WNorth-R304';
  }

  Future<Map<String, String>?> detectResQNetwork() async {
    final ssid = await getCurrentSSID();
    if (ssid != null && ssid.startsWith('ResQ-')) {
      final parts = ssid.split('-');
      if (parts.length >= 4) {
        return {
          'floor': parts[1].substring(1),
          'wing': parts[2].substring(1),
          'room': parts[3].substring(1),
        };
      }
    }
    return null;
  }
}
