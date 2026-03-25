import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/attendance_api_service.dart';
import '../services/face_service.dart';

enum CameraFlowMode { registerFace, markAttendance }

class CameraScreen extends StatefulWidget {
  final String apiBaseUrl;
  final CameraFlowMode mode;
  final String? studentId;

  const CameraScreen({
    super.key,
    required this.apiBaseUrl,
    required this.mode,
    this.studentId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final FaceService _faceService = FaceService();

  CameraController? _cameraController;
  late final AttendanceApiService _api;
  bool _isLoadingCamera = true;
  bool _isProcessing = false;

  String _message = 'Align your face and capture.';
  Color _messageColor = Colors.black87;

  @override
  void initState() {
    super.initState();
    _api = AttendanceApiService(baseUrl: widget.apiBaseUrl);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front);
      final selected = front.isNotEmpty ? front.first : cameras.first;

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isLoadingCamera = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCamera = false;
        _message = 'Failed to initialize camera: $e';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _message = 'Processing face...';
      _messageColor = Colors.black87;
    });

    try {
      final XFile image = await controller.takePicture();
      final detection = await _faceService.detectFacesFromPath(image.path);

      if (detection.faces.isEmpty) {
        _setMessage('No face detected. Please try again.', Colors.red);
        return;
      }

      if (detection.faces.length > 1) {
        _setMessage('Multiple faces detected. Keep only one face in frame.', Colors.red);
        return;
      }

      final face = detection.faces.first;
      final imageSize = await _resolveImageSize(image.path);
      final embedding = _faceService.extractEmbedding(face, imageSize: imageSize);

      if (widget.mode == CameraFlowMode.registerFace) {
        await _handleRegistration(embedding);
      } else {
        await _handleRecognitionAndAttendance(embedding);
      }
    } catch (e) {
      _setMessage('Processing failed: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleRegistration(List<double> embedding) async {
    final studentId = widget.studentId?.trim() ?? '';
    if (studentId.isEmpty) {
      _setMessage('studentId is required for registration.', Colors.red);
      return;
    }

    final outcome = await _api.registerFace(
      studentId: studentId,
      embedding: embedding,
    );

    if (outcome.success) {
      _setMessage(outcome.message, Colors.green);
    } else {
      _setMessage(outcome.message, Colors.red);
    }
  }

  Future<void> _handleRecognitionAndAttendance(List<double> probeEmbedding) async {
    final records = await _api.getAllEmbeddings();
    if (records.isEmpty) {
      _setMessage('No registered faces found.', Colors.red);
      return;
    }

    final match = _faceService.findBestMatch(
      probeEmbedding: probeEmbedding,
      candidates: records,
    );

    if (match == null) {
      _setMessage('Face not recognized.', Colors.red);
      return;
    }

    final attendance = await _api.markAttendance(studentId: match.studentId);
    if (attendance.success) {
      _setMessage(
        'Matched ${match.studentId}. ${attendance.message}',
        Colors.green,
      );
      return;
    }

    if (attendance.code == 'DUPLICATE_ATTENDANCE') {
      _setMessage(attendance.message, Colors.red);
      return;
    }
    if (attendance.code == 'INVALID_TIME') {
      _setMessage(attendance.message, Colors.orange.shade800);
      return;
    }

    _setMessage(attendance.message, Colors.red);
  }

  Future<Size> _resolveImageSize(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
  }

  void _setMessage(String value, Color color) {
    if (!mounted) return;
    setState(() {
      _message = value;
      _messageColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == CameraFlowMode.registerFace
        ? 'Register Face'
        : 'Mark Attendance';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingCamera
                ? const Center(child: CircularProgressIndicator())
                : (_cameraController == null
                    ? const Center(child: Text('Camera unavailable'))
                    : CameraPreview(_cameraController!)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _message,
                  style: TextStyle(color: _messageColor),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _captureAndProcess,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Capture'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
