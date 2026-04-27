import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool _meshActive = false;

  bool get isOnline => _isOnline;
  bool get meshActive => _meshActive;

  void updateConnection(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  void setMesh(bool active) {
    _meshActive = active;
    notifyListeners();
  }
}
