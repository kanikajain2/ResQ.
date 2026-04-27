class AnalyticsModel {
  final int totalIncidentsThisWeek;
  final double falseAlarmRate;
  final double avgResponseTimeMinutes;
  final int incidentsResolvedToday;
  final Map<String, int> incidentsByDay;
  final Map<String, int> incidentsByType;
  final Map<String, double> responseTimesByDay;
  final List<Map<String, dynamic>> topFalseAlarmRooms;

  AnalyticsModel({
    required this.totalIncidentsThisWeek,
    required this.falseAlarmRate,
    required this.avgResponseTimeMinutes,
    required this.incidentsResolvedToday,
    required this.incidentsByDay,
    required this.incidentsByType,
    required this.responseTimesByDay,
    required this.topFalseAlarmRooms,
  });

  factory AnalyticsModel.empty() {
    return AnalyticsModel(
      totalIncidentsThisWeek: 0,
      falseAlarmRate: 0.0,
      avgResponseTimeMinutes: 0.0,
      incidentsResolvedToday: 0,
      incidentsByDay: {},
      incidentsByType: {},
      responseTimesByDay: {},
      topFalseAlarmRooms: [],
    );
  }
}
