// lib/services/sms_service.dart
// VIRA — Sends SMS using Android's native SmsManager directly via platform channel
// Avoids the 'telephony' package's broken broadcast receiver on Android 12+

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  static const MethodChannel _channel =
      MethodChannel('com.example.women_safety_app/sms');

  // ── Request SMS Permission ────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    final status = await Permission.sms.status;
    print('📱 Current SMS permission status: $status');

    if (status.isGranted) return true;

    final result = await Permission.sms.request();
    print('📱 SMS permission after request: $result');
    return result.isGranted;
  }

  // ── Send SOS SMS to all contacts ──────────────────────────────────────────

  static Future<void> sendSOSToContacts({
    required List<Map<String, dynamic>> contacts,
    required String senderName,
    required double latitude,
    required double longitude,
  }) async {
    print('📨 sendSOSToContacts called with ${contacts.length} contacts');

    final granted = await requestPermission();
    if (!granted) {
      print('❌ SMS permission NOT granted — aborting send');
      return;
    }

    if (contacts.isEmpty) {
      print('❌ Contacts list is EMPTY — nothing to send to');
      return;
    }

    final mapsLink = 'https://www.google.com/maps?q=$latitude,$longitude';

    final message =
        '🚨 EMERGENCY ALERT from VIRA\n\n'
        '$senderName needs help RIGHT NOW!\n\n'
        '📍 Live Location:\n$mapsLink\n\n'
        'Please call them immediately or contact police (100).\n\n'
        '— Sent via VIRA Safety App';

    for (final contact in contacts) {
      final phone = contact['phone'] as String?;
      print('📞 Processing contact: name=${contact['name']}, phone=$phone');

      if (phone == null || phone.isEmpty) {
        print('⚠️ Skipping — phone is null/empty');
        continue;
      }

      try {
        print('📤 Sending native SMS to $phone...');
        final result = await _channel.invokeMethod('sendSms', {
          'phone': phone,
          'message': message,
        });
        print('✅ Native SMS result for $phone: $result');
      } catch (e) {
        print('❌ Error sending SMS to $phone: $e');
      }
    }
  }
}