import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    await _fcm.requestPermission();
    String? token = await _fcm.getToken();
    print("FCM Token: $token");
    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.notification?.title}");
    });
  }

  Future<void> subscribeToRole(String role) async {
    await _fcm.subscribeToTopic('role_$role');
  }
}
