// lib/services/firestore_services.dart
// VIRA — Fixed: contacts fetched from /contacts sub-collection correctly

import 'dart:async';
import 'api_service.dart';

class FirestoreService {
  String? _activeAlertId;

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      return await ApiService.get('/profile');
    } on ApiException {
      return null;
    }
  }

  Stream<_FakeSnapshot> getUserStream() async* {
    try {
      final data = await ApiService.get('/profile');
      yield _FakeSnapshot(data);
    } catch (_) {
      yield _FakeSnapshot({});
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> fields) async {
    await ApiService.put('/profile', fields);
  }

  // ── Contacts ──────────────────────────────────────────────────────────────

  /// Returns list of contacts from GET /contacts
  /// Each contact has: id, name, phone, email, relationship
  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      //print('📋 getContacts() — calling GET /contacts...');
      final response = await ApiService.getRaw('/contacts');
      //print('📋 Raw response type: ${response.runtimeType}');
      //print('📋 Raw response: $response');
      if (response is List) {
        final list = response.cast<Map<String, dynamic>>();
        //print('📋 Parsed as List — ${list.length} contacts');
        return list;
      }
      final wrapped = response as Map<String, dynamic>;
      final list = wrapped['contacts'] as List<dynamic>? ?? [];
      print('📋 Parsed as Map — ${list.length} contacts');
      return list.cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      print('❌ getContacts ApiException: ${e.statusCode} — ${e.message}');
      return [];
    } catch (e) {
      print('❌ getContacts error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addContact({
    required String name,
    required String phone,
    String relationship = '',
  }) async {
    return await ApiService.post('/contacts', {
      'name': name,
      'phone': phone,
      if (relationship.isNotEmpty) 'relationship': relationship,
    }, auth: true);
  }

  Future<void> deleteContact(String contactId) async {
    await ApiService.delete('/contacts/$contactId');
  }

  // ── SOS ───────────────────────────────────────────────────────────────────

  Future<void> triggerSOS({
    required String emergencyNumber,
    required List<Map<String, dynamic>> trustedContacts,
    double latitude = 22.5726,
    double longitude = 88.3639,
  }) async {
    final response = await ApiService.post('/sos/trigger', {
      'latitude': latitude,
      'longitude': longitude,
      'emergency_number': emergencyNumber,
      'trusted_contacts': trustedContacts,
    }, auth: true);

    _activeAlertId = response['alert_id'] as String?;
  }

  Future<void> cancelSOS() async {
    if (_activeAlertId == null) {
      try {
        final history = await getSOSHistory();
        final active = history.where((a) => a['status'] == 'active').toList();
        if (active.isNotEmpty) {
          _activeAlertId = active.first['alert_id'] as String?;
        }
      } catch (_) {}
    }

    if (_activeAlertId == null) return;

    await ApiService.post('/sos/cancel', {
      'alert_id': _activeAlertId,
    }, auth: true);

    _activeAlertId = null;
  }

  Future<List<Map<String, dynamic>>> getSOSHistory() async {
    final response = await ApiService.getRaw('/sos/history');
    if (response is List) {
      return response.cast<Map<String, dynamic>>();
    }
    final wrapped = response as Map<String, dynamic>;
    final list = wrapped['alerts'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  // ── Live Location ─────────────────────────────────────────────────────────

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    await ApiService.put('/location', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}

class _FakeSnapshot {
  final Map<String, dynamic> _data;
  _FakeSnapshot(this._data);
  Map<String, dynamic> data() => _data;
}

// OLD CODE --> 

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   String get _uid => _auth.currentUser!.uid;

//   // ── USER PROFILE ──────────────────────────────────────────────

//   Future<Map<String, dynamic>?> getUserProfile() async {
//     final doc = await _db.collection('users').doc(_uid).get();
//     return doc.data();
//   }

//   Stream<DocumentSnapshot> getUserStream() {
//     return _db.collection('users').doc(_uid).snapshots();
//   }

//   Future<void> updateUserProfile(Map<String, dynamic> data) async {
//     await _db.collection('users').doc(_uid).update(data);
//   }

//   // ── TRUSTED CONTACTS ─────────────────────────────────────────

//   Future<void> addTrustedContact({
//     required String name,
//     required String phone,
//     required String relation,
//   }) async {
//     final contact = {
//       'id': DateTime.now().millisecondsSinceEpoch.toString(),
//       'name': name,
//       'phone': phone,
//       'relation': relation,
//       'addedAt': FieldValue.serverTimestamp(),
//     };

//     await _db.collection('users').doc(_uid).update({
//       'trustedContacts': FieldValue.arrayUnion([contact]),
//     });
//   }

//   Future<void> removeTrustedContact(Map<String, dynamic> contact) async {
//     await _db.collection('users').doc(_uid).update({
//       'trustedContacts': FieldValue.arrayRemove([contact]),
//     });
//   }

//   Stream<List<Map<String, dynamic>>> getTrustedContacts() {
//     return _db.collection('users').doc(_uid).snapshots().map((doc) {
//       final data = doc.data();
//       if (data == null) return [];
//       final contacts = data['trustedContacts'] as List<dynamic>? ?? [];
//       return contacts.map((c) => Map<String, dynamic>.from(c as Map)).toList();
//     });
//   }

//   // ── LOCATION UPDATES ─────────────────────────────────────────

//   Future<void> updateUserLocation({
//     required double lat,
//     required double lng,
//     String? address,
//   }) async {
//     await _db.collection('users').doc(_uid).update({
//       'lastLocation': {
//         'lat': lat,
//         'lng': lng,
//         'address': address ?? '',
//         'timestamp': FieldValue.serverTimestamp(),
//       },
//     });
//   }

//   // ── SOS ALERTS ───────────────────────────────────────────────

//   Future<String> createSOSAlert({
//     required double lat,
//     required double lng,
//     required String address,
//     required List<Map<String, dynamic>> contacts,
//   }) async {
//     final alertRef = await _db.collection('sos_alerts').add({
//       'uid': _uid,
//       'userName': _auth.currentUser?.displayName ?? 'Unknown',
//       'userPhone': '',
//       'lat': lat,
//       'lng': lng,
//       'address': address,
//       'contacts': contacts,
//       'status': 'active',        // active | resolved
//       'createdAt': FieldValue.serverTimestamp(),
//       'resolvedAt': null,
//     });

//     // Also update user doc with active SOS flag
//     await _db.collection('users').doc(_uid).update({
//       'activeSOSId': alertRef.id,
//       'sosActive': true,
//     });

//     return alertRef.id;
//   }

//   Future<void> resolveSOSAlert(String alertId) async {
//     await _db.collection('sos_alerts').doc(alertId).update({
//       'status': 'resolved',
//       'resolvedAt': FieldValue.serverTimestamp(),
//     });
//     await _db.collection('users').doc(_uid).update({
//       'activeSOSId': null,
//       'sosActive': false,
//     });
//   }

//   Stream<QuerySnapshot> getSOSHistory() {
//     return _db
//         .collection('sos_alerts')
//         .where('uid', isEqualTo: _uid)
//         .orderBy('createdAt', descending: true)
//         .limit(20)
//         .snapshots();
//   }
// }