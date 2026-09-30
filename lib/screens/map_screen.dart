// lib/screens/map_screen.dart
// VIRA — Unified Live Location screen with REAL embedded Google Map
// This is now the SINGLE source of truth for all location-related UI:
// share, copy, live tracking — all on top of a live map with pin.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_services.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Color pink = Color(0xFFE91E8C);
  static const Color dark = Color(0xFF222222);
  static const Color gray = Color(0xFF666666);
  static const Color pinkLight = Color(0xFFFFD6E7);

  final Completer<GoogleMapController> _mapController = Completer();
  final _db = FirestoreService();

  static const LatLng _defaultLocation = LatLng(22.5726, 88.3639);

  LatLng _currentLocation = _defaultLocation;
  bool _locationLoaded = false;
  bool _loading = true;
  String _statusText = 'Getting your location...';

  final Set<Marker> _markers = {};

  StreamSubscription<Position>? _positionStream;
  bool _liveTracking = false;

  @override
  void initState() {
    super.initState();
    _getInitialLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // ── Get Initial Location ──────────────────────────────────────────────────

  Future<void> _getInitialLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loading = false;
            _statusText = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loading = false;
          _statusText = 'Location permission permanently denied';
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loading = false;
          _statusText = 'Please enable location services';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _updateLocation(LatLng(position.latitude, position.longitude));
      setState(() {
        _loading = false;
        _statusText = 'Live Location';
        _locationLoaded = true;
      });

      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: 16),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _statusText = 'Could not get location';
      });
    }
  }

  void _updateLocation(LatLng pos) {
    setState(() {
      _currentLocation = pos;
      _markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('my_location'),
          position: pos,
          infoWindow: const InfoWindow(
            title: '📍 You are here',
            snippet: 'Your current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ));
    });
  }

  // ── Start / Stop Live Tracking ────────────────────────────────────────────

  void _startLiveTracking() {
    setState(() => _liveTracking = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) async {
      final newPos = LatLng(position.latitude, position.longitude);
      _updateLocation(newPos);

      // Send to backend too
      try {
        await _db.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {}

      final controller = await _mapController.future;
      controller.animateCamera(CameraUpdate.newLatLng(newPos));
    });
  }

  void _stopLiveTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() => _liveTracking = false);
  }

  Future<void> _centerOnMe() async {
    final controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentLocation, zoom: 16),
      ),
    );
  }

  // ── Share Actions ──────────────────────────────────────────────────────────

  String get _mapsLink =>
      'https://maps.google.com/?q=${_currentLocation.latitude},${_currentLocation.longitude}';

  Future<void> _shareViaWhatsApp() async {
    final text = Uri.encodeComponent(
      '📍 My Live Location:\n$_mapsLink',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _toast('Could not open WhatsApp');
    }
  }

  Future<void> _shareViaSms() async {
    final body = Uri.encodeComponent('📍 My Live Location:\n$_mapsLink');
    final uri = Uri.parse('sms:?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _toast('Could not open Messages');
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _mapsLink));
    _toast('Location link copied!');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: pink, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
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
            decoration: const BoxDecoration(color: pink, shape: BoxShape.circle),
            child: const Icon(Icons.location_on, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Live Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: dark)),
            Text(
              _liveTracking ? 'Tracking active' : _statusText,
              style: TextStyle(
                fontSize: 11,
                color: _liveTracking ? Colors.green : gray,
                fontWeight: _liveTracking ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ]),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: pinkLight, height: 1),
        ),
        actions: [
          GestureDetector(
            onTap: _liveTracking ? _stopLiveTracking : _startLiveTracking,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _liveTracking ? Colors.green : pink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_liveTracking ? Icons.stop : Icons.play_arrow, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  _liveTracking ? 'Stop' : 'Live',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ),
        ],
      ),
      body: Stack(children: [
        // ── Real Embedded Google Map ────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentLocation, zoom: 15),
          onMapCreated: (controller) => _mapController.complete(controller),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),

        // ── Loading overlay ─────────────────────────────────────────────────
        if (_loading)
          Container(
            color: Colors.white.withOpacity(0.85),
            child: const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(color: pink),
                SizedBox(height: 16),
                Text('Getting your location...', style: TextStyle(color: gray, fontSize: 14)),
              ]),
            ),
          ),

        // ── Bottom Info Card (with Share buttons) ───────────────────────────
        if (!_loading && _locationLoaded)
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: pinkLight),
                boxShadow: [
                  BoxShadow(color: Colors.pink.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.location_on, color: pink, size: 18),
                  const SizedBox(width: 6),
                  const Text('Your Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: dark)),
                  const Spacer(),
                  if (_liveTracking)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 4),
                        Text('Live', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 8),

                Row(children: [
                  Expanded(child: _coordCard('Latitude', _currentLocation.latitude.toStringAsFixed(6), Icons.swap_vert)),
                  const SizedBox(width: 10),
                  Expanded(child: _coordCard('Longitude', _currentLocation.longitude.toStringAsFixed(6), Icons.swap_horiz)),
                ]),
                const SizedBox(height: 12),

                // Share row 1 — WhatsApp + SMS
                Row(children: [
                  Expanded(child: _actionBtn(Icons.chat_outlined, 'WhatsApp', _shareViaWhatsApp, filled: false)),
                  const SizedBox(width: 10),
                  Expanded(child: _actionBtn(Icons.sms_outlined, 'SMS', _shareViaSms, filled: false)),
                ]),
                const SizedBox(height: 8),
                // Share row 2 — Copy
                Row(children: [
                  Expanded(child: _actionBtn(Icons.copy, 'Copy Link', _copyLink, filled: true)),
                ]),
              ]),
            ),
          ),

        // ── Center on me button ─────────────────────────────────────────────
        if (!_loading)
          Positioned(
            bottom: _locationLoaded ? 280 : 24,
            right: 16,
            child: GestureDetector(
              onTap: _centerOnMe,
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: pinkLight),
                  boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.15), blurRadius: 10)],
                ),
                child: const Icon(Icons.my_location, color: pink, size: 22),
              ),
            ),
          ),
      ]),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _coordCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pinkLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: pink, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: gray, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: dark)),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap, {required bool filled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? pink : const Color(0xFFFFF0F5),
          border: filled ? null : Border.all(color: pinkLight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: filled ? Colors.white : pink, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: filled ? Colors.white : pink)),
        ]),
      ),
    );
  }
}
