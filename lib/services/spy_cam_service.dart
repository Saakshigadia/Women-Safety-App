// lib/services/spy_cam_service.dart

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SpyCamService {
  CameraController? controller;
  List<CameraDescription> _cameras = [];

  bool isInitialized = false;
  bool isRecording = false;

  Timer? _segmentTimer;
  final List<String> savedSegments = [];

  /// Requests Camera + Microphone + Storage permissions.
  Future<bool> requestCameraPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    return statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted;
  }

  /// Call once before showing the preview.
  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('NoCamera', 'No cameras found on this device.');
    }

    final backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await controller!.initialize();
    isInitialized = true;
  }

  /// Starts recording with auto-split every [segmentLength].
  Future<void> startRecording({
    Duration segmentLength = const Duration(minutes: 5),
    void Function(String path)? onSegmentSaved,
  }) async {
    if (controller == null || !isInitialized) {
      throw StateError('Call initialize() before startRecording().');
    }
    if (isRecording) return;

    await controller!.startVideoRecording();
    isRecording = true;

    _segmentTimer = Timer.periodic(segmentLength, (_) async {
      if (!isRecording || controller == null) return;
      final path = await _stopAndSaveSegment();
      if (path != null) {
        savedSegments.add(path);
        onSegmentSaved?.call(path);
      }
      if (isRecording) {
        await controller!.startVideoRecording();
      }
    });
  }

  /// Stops recording entirely.
  Future<String?> stopRecording() async {
    if (!isRecording) return null;
    isRecording = false;
    _segmentTimer?.cancel();
    _segmentTimer = null;
    return _stopAndSaveSegment();
  }

  Future<String?> _stopAndSaveSegment() async {
    if (controller == null || !controller!.value.isRecordingVideo) return null;

    final XFile rawFile = await controller!.stopVideoRecording();

    // Try to save to a visible public folder first
    Directory? viraDir;

    try {
      // getExternalStorageDirectory() gives:
      //   /storage/emulated/0/Android/data/<package>/files
      // Split at "Android" to get the public root:
      //   /storage/emulated/0/
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final publicRoot = extDir.path.split('Android')[0];
        viraDir = Directory('${publicRoot}Movies/VIRA');
        print('📂 Trying public path: ${viraDir.path}');
      }
    } catch (e) {
      print('⚠️ Could not get external dir: $e');
    }

    // Fallback — always works, private to the app
    viraDir ??= Directory(
      '${(await getApplicationDocumentsDirectory()).path}/VIRA',
    );

    if (!await viraDir.exists()) {
      await viraDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final savedPath = '${viraDir.path}/spycam_$timestamp.mp4';
    await File(rawFile.path).copy(savedPath);

    print('✅ VIDEO SAVED TO: $savedPath');
    return savedPath;
  }

  Future<void> dispose() async {
    _segmentTimer?.cancel();
    if (controller != null && controller!.value.isRecordingVideo) {
      await controller!.stopVideoRecording();
    }
    await controller?.dispose();
    isInitialized = false;
    isRecording = false;
  }
}