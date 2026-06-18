import 'package:geolocator/geolocator.dart';

/// Thin wrapper around geolocator.
/// GPS is optional — if unavailable, returns null and chat continues normally.
/// Shared between Chat (Person 4) and Search (Person 2).
class LocationService {
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled at the device level
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      // GPS failure should never block the chat
      return null;
    }
  }
}
