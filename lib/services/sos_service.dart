// lib/services/sos_service.dart
// VIRA — Complete SOS flow:
//   1. Get real GPS coordinates
//   2. Fetch trusted contacts from /contacts API
//   3. Save SOS alert to Firestore via /sos/trigger
//   4. Send real SMS to all trusted contacts with location link

import 'package:geolocator/geolocator.dart';
import 'firestore_services.dart';
import 'sms_service.dart';
import 'auth_services.dart';

class SOSService {
  final _db = FirestoreService();
  final _auth = AuthService();

  // ── Trigger SOS ───────────────────────────────────────────────────────────

  Future<void> triggerSOS({
    required String emergencyNumber,
    required List<Map<String, dynamic>> trustedContacts,
  }) async {
    // Step 1 — Get real GPS
    double latitude = 22.5726;   // Kolkata fallback
    double longitude = 88.3639;

    try {
      final position = await _getPosition();
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
      }
    } catch (_) {}

    // Step 2 — Fetch real contacts from /contacts API
    List<Map<String, dynamic>> contacts = [];
    try {
      contacts = await _db.getContacts();
    } catch (_) {
      // Fall back to passed-in contacts if fetch fails
      contacts = trustedContacts;
    }

    // Step 3 — Save SOS alert to Firestore via FastAPI
    try {
      await _db.triggerSOS(
        emergencyNumber: contacts.isNotEmpty
            ? (contacts.first['phone'] as String? ?? '112')
            : '112',
        trustedContacts: contacts,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (_) {}

    // Step 4 — Send real SMS to all trusted contacts
    if (contacts.isNotEmpty) {
      // Get sender's name from /auth/me
      String senderName = 'VIRA User';
      try {
        final user = await _auth.getCurrentUser();
        senderName = user?['name'] as String? ?? 'VIRA User';
      } catch (_) {}

      await SmsService.sendSOSToContacts(
        contacts: contacts,
        senderName: senderName,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  // ── Cancel SOS ────────────────────────────────────────────────────────────

  Future<void> cancelSOS() async {
    await _db.cancelSOS();
  }

  // ── Get GPS Position ──────────────────────────────────────────────────────

  Future<Position?> _getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}



// OLD CODE -->

// import 'package:geolocator/geolocator.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'location_services.dart';
// import 'firestore_services.dart';

// class SOSService {
//   final LocationService _locationService = LocationService();
//   final FirestoreService _firestoreService = FirestoreService();

//   String? _activeAlertId;
//   bool _isActive = false;

//   bool get isActive => _isActive;
//   String? get activeAlertId => _activeAlertId;

//   /// Trigger SOS: gets location, saves alert to Firestore, makes emergency call
//   Future<SOSResult> triggerSOS({
//     String? emergencyNumber,
//     List<Map<String, dynamic>>? trustedContacts,
//   }) async {
//     try {
//       // 1. Get current location
//       final Position? position = await _locationService.getCurrentPosition();

//       double lat = 0.0, lng = 0.0;
//       String address = 'Location unavailable';

//       if (position != null) {
//         lat = position.latitude;
//         lng = position.longitude;
//         address = await _locationService.getAddressFromCoords(lat, lng);
//       }

//       // 2. Save SOS alert to Firestore
//       _activeAlertId = await _firestoreService.createSOSAlert(
//         lat: lat,
//         lng: lng,
//         address: address,
//         contacts: trustedContacts ?? [],
//       );

//       _isActive = true;

//       // 3. Make emergency phone call
//       if (emergencyNumber != null && emergencyNumber.isNotEmpty) {
//         await _makeEmergencyCall(emergencyNumber);
//       }

//       return SOSResult(
//         success: true,
//         alertId: _activeAlertId!,
//         lat: lat,
//         lng: lng,
//         address: address,
//         mapsLink: _locationService.getMapsLink(lat, lng),
//       );
//     } catch (e) {
//       return SOSResult(success: false, error: e.toString());
//     }
//   }

//   /// Cancel / resolve the active SOS
//   Future<void> cancelSOS() async {
//     if (_activeAlertId != null) {
//       await _firestoreService.resolveSOSAlert(_activeAlertId!);
//       _activeAlertId = null;
//       _isActive = false;
//     }
//   }

//   /// Dial a number directly
//   Future<void> _makeEmergencyCall(String number) async {
//     final uri = Uri(scheme: 'tel', path: number);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }

//   /// Quick call — can be used outside SOS context (e.g., call police directly)
//   Future<void> callNumber(String number) async {
//     final uri = Uri(scheme: 'tel', path: number);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     }
//   }

//   /// Open location in Google Maps
//   Future<void> openMapsLocation(double lat, double lng) async {
//     final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }
// }

// class SOSResult {
//   final bool success;
//   final String? alertId;
//   final double? lat;
//   final double? lng;
//   final String? address;
//   final String? mapsLink;
//   final String? error;

//   SOSResult({
//     required this.success,
//     this.alertId,
//     this.lat,
//     this.lng,
//     this.address,
//     this.mapsLink,
//     this.error,
//   });
// }