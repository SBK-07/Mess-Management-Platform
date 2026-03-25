import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'attendance_api_service.dart';

class FaceDetectionResult {
  final List<Face> faces;
  final InputImage inputImage;

  const FaceDetectionResult({
    required this.faces,
    required this.inputImage,
  });
}

class FaceMatchResult {
  final String studentId;
  final double cosineScore;
  final double euclideanDistance;

  const FaceMatchResult({
    required this.studentId,
    required this.cosineScore,
    required this.euclideanDistance,
  });
}

class FaceService {
  FaceService()
      : _detector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,
            enableLandmarks: true,
            enableContours: true,
            enableClassification: false,
            enableTracking: false,
          ),
        );

  final FaceDetector _detector;

  Future<FaceDetectionResult> detectFacesFromPath(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _detector.processImage(inputImage);
    return FaceDetectionResult(faces: faces, inputImage: inputImage);
  }

  List<double> extractEmbedding(
    Face face, {
    required Size imageSize,
  }) {
    final vector = <double>[];

    final rect = face.boundingBox;
    final imageW = max(imageSize.width, 1);
    final imageH = max(imageSize.height, 1);

    final centerX = rect.center.dx / imageW;
    final centerY = rect.center.dy / imageH;
    final widthN = rect.width / imageW;
    final heightN = rect.height / imageH;

    vector.addAll([
      centerX,
      centerY,
      widthN,
      heightN,
      (face.headEulerAngleX ?? 0) / 90,
      (face.headEulerAngleY ?? 0) / 90,
      (face.headEulerAngleZ ?? 0) / 90,
    ]);

    final landmarkOrder = <FaceLandmarkType>[
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
    ];

    for (final type in landmarkOrder) {
      final landmark = face.landmarks[type];
      if (landmark == null) {
        vector.addAll(const [-1.0, -1.0]);
        continue;
      }
      final point = landmark.position;
      final x = (point.x - rect.left) / max(rect.width, 1);
      final y = (point.y - rect.top) / max(rect.height, 1);
      vector.addAll([x, y]);
    }

    _appendDistanceFeature(
      vector,
      face,
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      rect,
    );
    _appendDistanceFeature(
      vector,
      face,
      FaceLandmarkType.leftEye,
      FaceLandmarkType.noseBase,
      rect,
    );
    _appendDistanceFeature(
      vector,
      face,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      rect,
    );
    _appendDistanceFeature(
      vector,
      face,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      rect,
    );
    _appendDistanceFeature(
      vector,
      face,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.bottomMouth,
      rect,
    );

    return _l2Normalize(vector);
  }

  FaceMatchResult? findBestMatch({
    required List<double> probeEmbedding,
    required List<StoredEmbeddingRecord> candidates,
    double minCosine = 0.93,
    double maxEuclidean = 0.38,
  }) {
    FaceMatchResult? best;

    for (final candidate in candidates) {
      if (candidate.embedding.length != probeEmbedding.length) {
        continue;
      }

      final cosine = cosineSimilarity(probeEmbedding, candidate.embedding);
      final distance = euclideanDistance(probeEmbedding, candidate.embedding);

      final isAcceptable = cosine >= minCosine && distance <= maxEuclidean;
      if (!isAcceptable) {
        continue;
      }

      if (best == null || cosine > best.cosineScore) {
        best = FaceMatchResult(
          studentId: candidate.studentId,
          cosineScore: cosine,
          euclideanDistance: distance,
        );
      }
    }

    return best;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) {
      return -1;
    }

    double dot = 0;
    double aNorm = 0;
    double bNorm = 0;

    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      aNorm += a[i] * a[i];
      bNorm += b[i] * b[i];
    }

    if (aNorm == 0 || bNorm == 0) {
      return -1;
    }

    return dot / (sqrt(aNorm) * sqrt(bNorm));
  }

  double euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) {
      return double.infinity;
    }

    double sum = 0;
    for (var i = 0; i < a.length; i++) {
      final d = a[i] - b[i];
      sum += d * d;
    }
    return sqrt(sum);
  }

  Future<void> dispose() async {
    await _detector.close();
  }

  void _appendDistanceFeature(
    List<double> vector,
    Face face,
    FaceLandmarkType a,
    FaceLandmarkType b,
    Rect rect,
  ) {
    final la = face.landmarks[a];
    final lb = face.landmarks[b];
    if (la == null || lb == null) {
      vector.add(-1);
      return;
    }

    final dx = la.position.x - lb.position.x;
    final dy = la.position.y - lb.position.y;
    final d = sqrt(dx * dx + dy * dy);
    final diag = sqrt(rect.width * rect.width + rect.height * rect.height);
    vector.add(d / max(diag, 1));
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0;
    for (final v in vector) {
      sum += v * v;
    }
    final norm = sqrt(sum);
    if (norm == 0) {
      return List<double>.from(vector);
    }
    return vector.map((v) => v / norm).toList(growable: false);
  }
}
