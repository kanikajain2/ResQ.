class FirestorePaths {
  static const String incidents = 'incidents';
  static const String staff = 'staff';
  static const String rooms = 'rooms';
  static const String calls = 'calls';
  static const String notificationQueue = 'notification_queue';
  
  static String incidentMessages(String incidentId) => 'incidents/$incidentId/messages';
}
