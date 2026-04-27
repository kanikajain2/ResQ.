import 'package:flutter/material.dart';
import '../models/incident_model.dart';

class IncidentProvider extends ChangeNotifier {
  List<IncidentModel> _incidents = [];

  List<IncidentModel> get incidents => _incidents;

  void setIncidents(List<IncidentModel> list) {
    _incidents = list;
    notifyListeners();
  }

  IncidentModel? getById(String id) {
    try {
      return _incidents.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
