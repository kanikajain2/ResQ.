import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  Future<BitmapDescriptor> getMarkerIcon(int severity) async {
    return BitmapDescriptor.defaultMarkerWithHue(
      severity >= 4 ? BitmapDescriptor.hueRed : 
      severity >= 2 ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue
    );
  }
}
