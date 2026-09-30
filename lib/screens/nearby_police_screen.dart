// lib/screens/nearby_police_screen.dart
// VIRA — Nearby Police Station Finder (FREE — no Places API billing)
// Flow: Get GPS → Open Google Maps with police search near coordinates

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyPoliceScreen extends StatefulWidget {
  const NearbyPoliceScreen({super.key});

  @override
  State<NearbyPoliceScreen> createState() => _NearbyPoliceScreenState();
}

class _NearbyPoliceScreenState extends State<NearbyPoliceScreen> {
  static const Color pink      = Color(0xFFE91E8C);
  static const Color dark      = Color(0xFF222222);
  static const Color gray      = Color(0xFF666666);
  static const Color pinkLight = Color(0xFFFFD6E7);
  static const Color pinkSoft  = Color(0xFFFFF0F5);

  bool _loading = false;
  double? _lat;
  double? _lng;
  String _locationText = 'Tap below to find stations near you';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  // ── Get GPS Location ──────────────────────────────────────────────────────

  Future<void> _getLocation() async {
    setState(() => _loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _loading = false;
          _locationText = 'Location permission denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _loading = false;
        _locationText =
            '${_lat!.toStringAsFixed(4)}° N, ${_lng!.toStringAsFixed(4)}° E';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _locationText = 'Could not get location';
      });
    }
  }

  // ── Open Google Maps — Nearby Police Stations ─────────────────────────────

  Future<void> _openMapsPolice() async {
    Uri uri;

    if (_lat != null && _lng != null) {
      // Opens Google Maps centered on user with police search
      uri = Uri.parse(
        'https://www.google.com/maps/search/police+station/@$_lat,$_lng,15z',
      );
    } else {
      // Fallback — search without coordinates
      uri = Uri.parse(
        'https://www.google.com/maps/search/police+station+near+me',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Could not open Google Maps');
    }
  }

  // ── Open Google Maps — Navigate to nearest police ─────────────────────────

  Future<void> _openMapsNavigate() async {
    Uri uri;

    if (_lat != null && _lng != null) {
      // Directions mode — finds nearest police and navigates
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$_lat,$_lng'
        '&destination=police+station'
        '&travelmode=driving',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=police+station',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Could not open Google Maps');
    }
  }

  // ── Call Emergency ────────────────────────────────────────────────────────

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('Could not open dialler');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline, color: pink, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xFF1A0A12),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: dark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
                color: Color(0xFF1565C0), shape: BoxShape.circle),
            child: const Icon(Icons.local_police,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nearby Police',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800, color: dark)),
            Text('Find stations near you',
                style: TextStyle(fontSize: 11, color: gray)),
          ]),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: pinkLight, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: pink),
            onPressed: _getLocation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Location Card ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pinkLight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Row(children: [
                Icon(Icons.my_location, color: pink, size: 16),
                SizedBox(width: 8),
                Text('Your Location',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pink)),
              ]),
              const SizedBox(height: 10),
              _loading
                  ? const Row(children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: pink, strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Getting your location...',
                          style: TextStyle(color: gray, fontSize: 13)),
                    ])
                  : Row(children: [
                      Icon(
                        _lat != null
                            ? Icons.check_circle
                            : Icons.location_off,
                        color: _lat != null ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_locationText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _lat != null ? dark : Colors.red,
                            )),
                      ),
                    ]),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Emergency Numbers ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pinkLight),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.emergency, color: pink, size: 16),
                SizedBox(width: 8),
                Text('Emergency Numbers',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pink)),
              ]),
              const SizedBox(height: 12),
              _emergencyRow('Police', '100',
                  const Color(0xFF1565C0), () => _call('100')),
              const SizedBox(height: 8),
              _emergencyRow('Women Helpline', '1091',
                  const Color(0xFFE91E8C), () => _call('1091')),
              const SizedBox(height: 8),
              _emergencyRow('National Emergency', '112',
                  const Color(0xFFE53935), () => _call('112')),
            ]),
          ),
          const SizedBox(height: 14),

          // ── Find on Google Maps ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pinkLight),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.map_outlined, color: Color(0xFF1565C0), size: 16),
                SizedBox(width: 8),
                Text('Find on Google Maps',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0))),
              ]),
              const SizedBox(height: 6),
              const Text(
                'Google Maps will show all nearby police stations with their details, ratings, and directions.',
                style: TextStyle(fontSize: 12, color: gray, height: 1.5),
              ),
              const SizedBox(height: 14),

              // Show nearby button
              GestureDetector(
                onTap: _openMapsPolice,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_police,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Show Nearby Police Stations',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
              const SizedBox(height: 10),

              // Navigate button
              GestureDetector(
                onTap: _openMapsNavigate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: pinkSoft,
                    border: Border.all(color: const Color(0xFF1565C0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation,
                            color: Color(0xFF1565C0), size: 18),
                        SizedBox(width: 8),
                        Text('Navigate to Nearest Station',
                            style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // ── How it works ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: pinkLight),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.info_outline, color: pink, size: 16),
                SizedBox(width: 8),
                Text('How it works',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: pink)),
              ]),
              const SizedBox(height: 12),
              ...[
                ['📍', 'App gets your GPS coordinates'],
                ['🗺️', 'Opens Google Maps with your location'],
                ['🚔', 'Google Maps shows all nearby police stations'],
                ['📞', 'Tap any station to call or get directions'],
              ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Text(item[0], style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(item[1],
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: gray,
                                  height: 1.4))),
                    ]),
                  )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Emergency Row Widget ──────────────────────────────────────────────────

  Widget _emergencyRow(
      String label, String number, Color color, VoidCallback onCall) {
    return Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.phone, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: dark)),
        Text(number,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ])),
      GestureDetector(
        onTap: onCall,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(20)),
          child: const Text('Call',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}