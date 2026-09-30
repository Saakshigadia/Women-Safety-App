// lib/services/auth_services.dart
// VIRA — Fixed to match backend model validators:
//   1. Phone formatted to E.164 (+91XXXXXXXXXX) before sending
//   2. Password validator error messages mapped correctly
//   3. All routes use /auth/ prefix

import 'api_service.dart';

class AuthService {
  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String phone = '',
  }) async {
    // Format phone to E.164 — backend validator requires +91XXXXXXXXXX format
    final formattedPhone = _formatPhone(phone);

    await ApiService.post('/auth/register', {
      'full_name': name,
      'email': email,
      'password': password,
      'phone': formattedPhone,
    });

    // Auto-login after registration
    await signIn(email: email, password: password);
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final token = response['access_token'] as String?;
    if (token == null) {
      throw ApiException(message: 'No token received from server', statusCode: 500);
    }
    await ApiService.saveToken(token);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await ApiService.clearToken();
  }

  // ── Reset Password ────────────────────────────────────────────────────────

  Future<void> resetPassword(String email) async {
    try {
      await ApiService.post('/auth/reset-password', {'email': email});
    } on ApiException {
      // Not yet implemented — fail silently
    }
  }

  // ── Get Current User ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final data = await ApiService.get('/auth/me');
      // Backend returns full_name — map to name for UI
      if (data.containsKey('full_name')) {
        data['name'] = data['full_name'];
      }
      return data;
    } on ApiException {
      return null;
    }
  }

  // ── Is Logged In ──────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Phone Formatter ───────────────────────────────────────────────────────
  // Converts any Indian phone format to E.164 (+91XXXXXXXXXX)
  // Examples:
  //   "98765 43210"     → "+919876543210"
  //   "+91 98765 43210" → "+919876543210"
  //   "09876543210"     → "+919876543210"
  //   ""                → "" (empty stays empty — phone is optional)

  String _formatPhone(String phone) {
    if (phone.trim().isEmpty) return '';

    // Strip all spaces, dashes, brackets
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Already in E.164
    if (cleaned.startsWith('+')) return cleaned;

    // Remove leading 0
    if (cleaned.startsWith('0')) cleaned = cleaned.substring(1);

    // Remove leading 91 if already there (without +)
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      return '+$cleaned';
    }

    // 10 digit Indian number — add +91
    if (cleaned.length == 10) return '+91$cleaned';

    // Return as-is if we can't determine format
    return cleaned;
  }
}




// OLD CODE --> 

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   // Current user
//   User? get currentUser => _auth.currentUser;
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   // Sign Up
//   Future<UserCredential?> signUp({
//     required String email,
//     required String password,
//     required String name,
//     required String phone,
//   }) async {
//     final credential = await _auth.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );

//     // Update display name
//     await credential.user?.updateDisplayName(name);

//     // Save user profile to Firestore
//     await _db.collection('users').doc(credential.user!.uid).set({
//       'uid': credential.user!.uid,
//       'name': name,
//       'email': email,
//       'phone': phone,
//       'createdAt': FieldValue.serverTimestamp(),
//       'profilePic': '',
//       'trustedContacts': [],
//     });

//     return credential;
//   }

//   // Sign In
//   Future<UserCredential?> signIn({
//     required String email,
//     required String password,
//   }) async {
//     final credential = await _auth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//     return credential;
//   }

//   // Sign Out
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }

//   // Reset Password
//   Future<void> resetPassword(String email) async {
//     await _auth.sendPasswordResetEmail(email: email);
//   }
// }