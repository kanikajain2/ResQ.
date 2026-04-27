import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((result) => result != ConnectivityResult.none);
      if (wasOnline != _isOnline) {
        notifyListeners();
      }
    });
  }

  Future<String?> getWifiSSID() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.wifi)) {
      return "Hotel_Guest_WiFi"; 
    }
    return null;
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;
}
