// lib/services/location_service.dart
// VIRA — Live location tracking service
// Sends real GPS location to FastAPI PUT /location every 10 seconds when active

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'firestore_services.dart';

class LocationService {
  final _db = FirestoreService();
  Timer? _timer;
  bool _isTracking = false;

  // ── Request Permission ────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ── Get Current Position Once ─────────────────────────────────────────────

  static Future<Position?> getCurrentPosition() async {
    try {
      final granted = await requestPermission();
      if (!granted) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Start Live Tracking ───────────────────────────────────────────────────

  Future<void> startTracking() async {
    if (_isTracking) return;

    final granted = await requestPermission();
    if (!granted) return;

    _isTracking = true;

    // Send immediately on start
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _db.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {}

    // Then send every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _db.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {
        // Fail silently — don't interrupt tracking
      }
    });
  }

  // ── Stop Live Tracking ────────────────────────────────────────────────────

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _isTracking = false;
  }

  bool get isTracking => _isTracking;
}