import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'storage_service.dart';



class ScreenshotApiService {
  ScreenshotApiService._();

  static final ScreenshotApiService instance = ScreenshotApiService._();

  final StorageService _storageService = StorageService();

  Future<Map<String, dynamic>> createUserScreenshot(
    Map<String, dynamic> payload,
  ) async {
    final token = await _storageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : 'NO_TOKEN',
    };
    final url = Uri.parse(
      '${ApiService.baseUrl}/Screenshot/CreateUserScreenshot',
    );
    final bodyJson = jsonEncode(payload);

    debugPrint('[ScreenshotAPI] ──────────── REQUEST ────────────');
    debugPrint('[ScreenshotAPI] URL    : POST $url');
    debugPrint('[ScreenshotAPI] Token  : ${token != null ? "present (${token.length} chars)" : "MISSING — request will fail with 401"}');
    debugPrint('[ScreenshotAPI] Headers: $headers');
    debugPrint('[ScreenshotAPI] Body   : $bodyJson');
    debugPrint('[ScreenshotAPI] ─────────────────────────────────');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: bodyJson,
      );
      final body = utf8.decode(response.bodyBytes);

      debugPrint('[ScreenshotAPI] ──────────── RESPONSE ───────────');
      debugPrint('[ScreenshotAPI] Status : ${response.statusCode}');
      debugPrint('[ScreenshotAPI] Body   : $body');
      debugPrint('[ScreenshotAPI] ─────────────────────────────────');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[ScreenshotAPI] FAILED — HTTP ${response.statusCode}');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'message': body,
        };
      }

      final decoded = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);
      final success = decoded is Map<String, dynamic>
          ? decoded['status'] == 'success' || decoded['success'] == true
          : true;

      debugPrint('[ScreenshotAPI] SUCCESS — success=$success');
      return {
        'success': success,
        'statusCode': response.statusCode,
        'message': decoded is Map<String, dynamic>
            ? decoded['messageAr'] ?? decoded['message'] ?? ''
            : '',
        'data': decoded,
      };
    } catch (error, stackTrace) {
      debugPrint('[ScreenshotAPI] EXCEPTION: $error');
      debugPrint('[ScreenshotAPI] $stackTrace');
      return {
        'success': false,
        'statusCode': null,
        'message': error.toString(),
      };
    }
  }

  Future<bool> blockOwnAccountOnScreenshotAbuse() async {
    final token = await _storageService.getToken();
    if (token == null) return false;

    final url = Uri.parse('${ApiService.baseUrl}/auth/BlockOnScreenshot');
    debugPrint('[ScreenshotAPI] Blocking account due to screenshot abuse...');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('[ScreenshotAPI] BlockOnScreenshot status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ScreenshotAPI] BlockOnScreenshot error: $e');
      return false;
    }
  }
}
