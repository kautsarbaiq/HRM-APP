import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'mock_data_service.dart';

class GeofenceResult {
  final bool isInRange;
  final double distanceMeters;
  final GeofenceLocation? nearestLocation;
  final Position? userPosition;
  final String? errorMessage;

  const GeofenceResult({
    required this.isInRange,
    this.distanceMeters = 0,
    this.nearestLocation,
    this.userPosition,
    this.errorMessage,
  });
}

class GeofenceService {
  /// Check if location services are enabled and permissions are granted.
  /// Returns null if OK, or an error message string.
  static Future<String?> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permission denied. Please allow location access.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permissions are permanently denied. Please enable them in Settings.';
    }

    return null; // All good
  }

  /// Get the user's current position.
  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Calculate distance between two lat/lng points using the Haversine formula.
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  /// Check if the user is within any authorized geofence location.
  static Future<GeofenceResult> checkGeofence() async {
    // Check permissions first
    final permError = await checkPermissions();
    if (permError != null) {
      return GeofenceResult(isInRange: false, errorMessage: permError);
    }

    try {
      final position = await getCurrentPosition();
      final locations = MockDataService.authorizedLocations;

      double minDistance = double.infinity;
      GeofenceLocation? nearest;

      for (final loc in locations) {
        final dist = calculateDistance(
          position.latitude, position.longitude,
          loc.latitude, loc.longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearest = loc;
        }
      }

      final isInRange = nearest != null && minDistance <= nearest.radiusMeters;

      return GeofenceResult(
        isInRange: isInRange,
        distanceMeters: minDistance,
        nearestLocation: nearest,
        userPosition: position,
      );
    } catch (e) {
      return GeofenceResult(
        isInRange: false,
        errorMessage: 'Failed to get location: ${e.toString()}',
      );
    }
  }
}
