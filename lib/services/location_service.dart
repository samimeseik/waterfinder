import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waterfinder/services/notification_service.dart';
import 'package:waterfinder/providers/water_source_provider.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final NotificationService _notificationService = NotificationService();
  bool _isTracking = false;

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      if (!await requestPermission()) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<void> startTracking(WaterSourceProvider sourceProvider) async {
    if (_isTracking) return;

    if (!await requestPermission()) {
      return;
    }

    _isTracking = true;

    // Set up location stream with appropriate settings for battery efficiency
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Update every 100 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) async {
      // Check for nearby water sources
      final sources = await sourceProvider.getNearbyWaterSources(
        position.toGeoPoint(),
        5.0, // 5km radius
      );

      await _notificationService.checkNearbyWaterSources(
        position,
        sources,
        5.0,
      );
    });
  }

  Future<void> stopTracking() async {
    _isTracking = false;
  }
}

extension PositionExtension on Position {
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }
}