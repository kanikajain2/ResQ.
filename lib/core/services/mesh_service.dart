import 'package:nearby_connections/nearby_connections.dart';

class MeshService {
  final Strategy strategy = Strategy.P2P_CLUSTER;
  final String userName = "Guest_${DateTime.now().millisecondsSinceEpoch}";

  Future<void> startMesh(Function(String) onAlertReceived) async {
    // 1. Start Advertising (I am here to help/receive)
    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(id, onPayLoadRecieved: (endpointId, payload) {
            if (payload.type == PayloadType.BYTES) {
              String msg = String.fromCharCodes(payload.bytes!);
              onAlertReceived(msg);
            }
          });
        },
        onConnectionResult: (id, status) {},
        onDisconnected: (id) {},
        serviceId: "com.resq.mesh",
      );

      // 2. Start Discovery (Look for others to send to)
      await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            userName,
            id,
            onConnectionInitiated: (id, info) {
              Nearby().acceptConnection(id, onPayLoadRecieved: (id, payload) {});
            },
            onConnectionResult: (id, status) {},
            onDisconnected: (id) {},
          );
        },
        onEndpointLost: (id) {},
        serviceId: "com.resq.mesh",
      );
    } catch (e) {
      print("Mesh Error: $e");
    }
  }

  Future<void> broadcastAlert(String alertJson) async {
    // Send to all connected endpoints
    // This logic would iterate through active connections
  }

  void stopMesh() {
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
  }
}
