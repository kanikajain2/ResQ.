import 'package:flutter/material.dart';

class SessionProvider extends ChangeNotifier {
  String? _uid;
  String? _name;
  String? _role;

  String? get uid => _uid;
  String? get name => _name;
  String? get role => _role;

  bool get isLoggedIn => _uid != null;

  void setSession({
    required String uid,
    required String name,
    required String role,
  }) {
    _uid = uid;
    _name = name;
    _role = role;
    notifyListeners();
  }

  void clearSession() {
    _uid = null;
    _name = null;
    _role = null;
    notifyListeners();
  }
}
