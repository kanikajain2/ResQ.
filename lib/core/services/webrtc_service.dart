import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  Future<void> init() async {
    final Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };
    _peerConnection = await createPeerConnection(configuration);
  }

  Future<MediaStream> createStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': true,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    return _localStream!;
  }

  Future<void> startCall(String incidentId) async {
    // Logic to create offer and save to Firestore
  }

  Future<void> answerCall(String incidentId) async {
    // Logic to read offer and create answer
  }

  void dispose() {
    _localStream?.dispose();
    _peerConnection?.dispose();
  }
}
