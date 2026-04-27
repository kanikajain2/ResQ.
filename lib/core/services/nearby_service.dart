import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService extends ChangeNotifier {
  static const String _serviceId = 'com.resq.emergency.mesh';
  final List<String> _connectedEndpoints = [];
  final List<Map<String, dynamic>> _receivedIncidents = [];
  Function(Map<String, dynamic>)? onSOSReceived;

  NearbyService({this.onSOSReceived});

  List<String> get connectedEndpoints => _connectedEndpoints;
  List<Map<String, dynamic>> get receivedIncidents => _receivedIncidents;
  bool get hasConnections => _connectedEndpoints.isNotEmpty;

  void clearReceivedIncidents() {
    _receivedIncidents.clear();
    notifyListeners();
  }

  Future<void> startAdvertising(String userName) async {
    try {
      bool hasPermissions = await _checkPermissions();
      if (!hasPermissions) return;

      await Nearby().startAdvertising(
        userName,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
    } catch (e) {
      debugPrint('Nearby advertising error: $e');
    }
  }

  Future<void> startDiscovery() async {
    try {
      bool hasPermissions = await _checkPermissions();
      if (!hasPermissions) return;

      await Nearby().startDiscovery(
        'discoverer',
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          Nearby().requestConnection(
            name, id,
            onConnectionInitiated: _onConnectionInitiated,
            onConnectionResult: _onConnectionResult,
            onDisconnected: _onDisconnected,
          );
        },
        onEndpointLost: (id) {
          _connectedEndpoints.remove(id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
    } catch (e) {
      debugPrint('Nearby discovery error: $e');
    }
  }

  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      if (!_connectedEndpoints.contains(id)) {
        _connectedEndpoints.add(id);
        notifyListeners();
      }
    }
  }

  void _onDisconnected(String id) {
    _connectedEndpoints.remove(id);
    notifyListeners();
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final data = jsonDecode(utf8.decode(payload.bytes!));
        if (data['type'] == 'sos_relay') {
          final incident = data['incident'];
          _receivedIncidents.add(incident as Map<String, dynamic>);
          notifyListeners();
          
          if (onSOSReceived != null) {
            onSOSReceived!(incident);
          }
        }
      } catch (e) {
        debugPrint('Payload parse error: $e');
      }
    }
  }

  Future<void> broadcastSOS(Map<String, dynamic> incidentData) async {
    final payload = jsonEncode({
      'type': 'sos_relay',
      'incident': incidentData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    final bytes = Uint8List.fromList(utf8.encode(payload));
    for (final endpointId in _connectedEndpoints) {
      try {
        await Nearby().sendBytesPayload(endpointId, bytes);
      } catch (e) {
        debugPrint('Send error to $endpointId: $e');
      }
    }
  }

  Future<void> stopAll() async {
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
      _connectedEndpoints.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Stop error: $e');
    }
  }
}
