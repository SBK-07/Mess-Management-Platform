import 'dart:convert';

import 'package:http/http.dart' as http;

class StoredEmbeddingRecord {
  final String studentId;
  final List<double> embedding;

  const StoredEmbeddingRecord({
    required this.studentId,
    required this.embedding,
  });

  factory StoredEmbeddingRecord.fromJson(Map<String, dynamic> json) {
    final rawEmbedding = (json['embedding'] as List<dynamic>? ?? <dynamic>[]);
    return StoredEmbeddingRecord(
      studentId: (json['studentId'] ?? '').toString(),
      embedding: rawEmbedding.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class ApiOutcome {
  final bool success;
  final String message;
  final String? code;
  final String? meal;

  const ApiOutcome({
    required this.success,
    required this.message,
    this.code,
    this.meal,
  });

  factory ApiOutcome.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return ApiOutcome(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      code: json['code']?.toString(),
      meal: data['meal']?.toString(),
    );
  }
}

class AttendanceApiService {
  final String baseUrl;

  const AttendanceApiService({required this.baseUrl});

  Future<ApiOutcome> registerFace({
    required String studentId,
    required List<double> embedding,
  }) async {
    final uri = Uri.parse('$baseUrl/register-face');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'studentId': studentId,
        'embedding': embedding,
      }),
    );

    return _parseOutcome(response, endpoint: uri.toString());
  }

  Future<List<StoredEmbeddingRecord>> getAllEmbeddings() async {
    final uri = Uri.parse('$baseUrl/face-embeddings');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    final Map<String, dynamic> body = _decodeJson(
      response.body,
      endpoint: uri.toString(),
      statusCode: response.statusCode,
    );
    final bool success = body['success'] == true;
    if (!success) {
      throw Exception(body['message'] ?? 'Failed to fetch embeddings.');
    }

    final data = (body['data'] as Map<String, dynamic>?) ?? const {};
    final rows = (data['records'] as List<dynamic>? ?? <dynamic>[]);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(StoredEmbeddingRecord.fromJson)
        .toList();
  }

  Future<ApiOutcome> markAttendance({required String studentId}) async {
    final uri = Uri.parse('$baseUrl/mark-attendance');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'studentId': studentId}),
    );

    return _parseOutcome(response, endpoint: uri.toString());
  }

  ApiOutcome _parseOutcome(http.Response response, {required String endpoint}) {
    final Map<String, dynamic> body = _decodeJson(
      response.body,
      endpoint: endpoint,
      statusCode: response.statusCode,
    );
    final result = ApiOutcome.fromJson(body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }
    return ApiOutcome(
      success: false,
      message: result.message.isEmpty ? 'Request failed.' : result.message,
      code: result.code,
      meal: result.meal,
    );
  }

  Map<String, dynamic> _decodeJson(
    String source, {
    required String endpoint,
    required int statusCode,
  }) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception('Unexpected response payload.');
    } catch (_) {
      final snippet = source.replaceAll('\n', ' ');
      final short = snippet.length > 160 ? '${snippet.substring(0, 160)}...' : snippet;
      throw Exception(
        'Invalid server response from $endpoint (HTTP $statusCode). Body: $short',
      );
    }
  }
}
