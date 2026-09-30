// lib/services/api_service.dart
// VIRA — Central HTTP client. JWT auto-injected on every request.
// Added getRaw() to handle endpoints that return a list directly.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🔧 Dev: http://10.0.2.2:8000  |  Prod: https://your-app.railway.app
  // static const String baseUrl = 'http://192.168.10.11:8000';

  static const String _localUrl = 'http://10.0.2.2:8000';
  static const String _productionUrl = 'https://vira-backend-qeog.onrender.com';

  static String get baseUrl => kReleaseMode ? _productionUrl : _localUrl;

  // ── Token Storage ─────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ── Header Builders ───────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static const Map<String, String> _plainHeaders = {
    'Content-Type': 'application/json',
  };

  // ── HTTP Helpers ──────────────────────────────────────────────────────────

  /// Standard GET — returns Map. Use for most endpoints.
  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
    );
    return _handleMap(response);
  }

  /// Raw GET — returns dynamic (List or Map).
  /// Use for endpoints that return a JSON array directly e.g. GET /sos/history
  static Future<dynamic> getRaw(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final detail = decoded['detail'];
    throw ApiException(
      message: detail is String ? detail : (detail?.toString() ?? 'Unknown error'),
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = auth ? await _authHeaders() : _plainHeaders;
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleMap(response);
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _handleMap(response);
  }

  static Future<void> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 204) {
      return; // success, no body to parse
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final detail = decoded['detail'];
    throw ApiException(
      message: detail is String ? detail : (detail?.toString() ?? 'Unknown error'),
      statusCode: response.statusCode,
    );
  }
  
  // ── Response Handlers ─────────────────────────────────────────────────────

  static Map<String, dynamic> _handleMap(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    final detail = decoded['detail'];
    throw ApiException(
      message: detail is String ? detail : (detail?.toString() ?? 'Unknown error'),
      statusCode: response.statusCode,
    );
  }
}

// ── Exception ─────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}




// OLD CODE -->

// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'firestore_services.dart';

// class LocationService {
//   final FirestoreService _firestoreService = FirestoreService();

//   // Check and request location permission
//   Future<bool> requestPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return false;

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) return false;
//     }
//     if (permission == LocationPermission.deniedForever) return false;

//     return true;
//   }

//   // Get current position once
//   Future<Position?> getCurrentPosition() async {
//     final hasPermission = await requestPermission();
//     if (!hasPermission) return null;

//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//       timeLimit: const Duration(seconds: 15),
//     );
//   }

//   // Get human-readable address from coordinates
//   Future<String> getAddressFromCoords(double lat, double lng) async {
//     try {
//       final placemarks = await placemarkFromCoordinates(lat, lng);
//       if (placemarks.isNotEmpty) {
//         final p = placemarks.first;
//         return '${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}';
//       }
//     } catch (_) {}
//     return '$lat, $lng';
//   }

//   // Start continuous location streaming and save to Firebase
//   Stream<Position> startLocationStream() {
//     const settings = LocationSettings(
//       accuracy: LocationAccuracy.high,
//       distanceFilter: 10, // Update every 10 metres
//     );

//     return Geolocator.getPositionStream(locationSettings: settings).map((pos) {
//       // Fire-and-forget: save to Firestore
//       _firestoreService.updateUserLocation(lat: pos.latitude, lng: pos.longitude);
//       return pos;
//     });
//   }

//   // Get Google Maps link for a position
//   String getMapsLink(double lat, double lng) {
//     return 'https://maps.google.com/?q=$lat,$lng';
//   }
// }