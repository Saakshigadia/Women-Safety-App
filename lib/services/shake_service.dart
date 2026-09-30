// lib/services/shake_service.dart
// VIRA — Shake detection using device accelerometer
// When user shakes phone hard (3 times), triggers SOS automatically

import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  // ── Configuration ─────────────────────────────────────────────────────────

  /// Acceleration threshold (m/s²) — higher = needs harder shake
  static const double _shakeThreshold = 18.0;

  /// Minimum time between detected shakes (avoid duplicate triggers)
  static const Duration _shakeCooldown = Duration(milliseconds: 800);

  /// Number of shakes needed within [_shakeCountWindow] to trigger SOS
  static const int _requiredShakeCount = 3;

  /// Time window to count shakes
  static const Duration _shakeCountWindow = Duration(seconds: 2);

  // ── State ─────────────────────────────────────────────────────────────────

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime _lastShakeTime = DateTime.now();
  int _shakeCount = 0;
  DateTime? _firstShakeTime;

  /// Called when shake pattern is detected (3 shakes within 2 seconds)
  final VoidCallback onShakeDetected;

  ShakeService({required this.onShakeDetected});

  // ── Start Listening ───────────────────────────────────────────────────────

  void start() {
    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_onAccelerometerEvent);
  }

  // ── Stop Listening ────────────────────────────────────────────────────────

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _shakeCount = 0;
    _firstShakeTime = null;
  }

  // ── Detect Shake ──────────────────────────────────────────────────────────

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate total acceleration magnitude (removing gravity ~9.8)
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    final acceleration = (magnitude - 9.8).abs();

    if (acceleration > _shakeThreshold) {
      final now = DateTime.now();

      // Enforce cooldown between individual shakes
      if (now.difference(_lastShakeTime) < _shakeCooldown) return;
      _lastShakeTime = now;

      // Start or continue counting shakes
      if (_firstShakeTime == null ||
          now.difference(_firstShakeTime!) > _shakeCountWindow) {
        // New shake sequence
        _firstShakeTime = now;
        _shakeCount = 1;
      } else {
        _shakeCount++;
      }

      // Trigger SOS if enough shakes within window
      if (_shakeCount >= _requiredShakeCount) {
        _shakeCount = 0;
        _firstShakeTime = null;
        onShakeDetected();
      }
    }
  }

  void dispose() {
    stop();
  }
}

typedef VoidCallback = void Function();