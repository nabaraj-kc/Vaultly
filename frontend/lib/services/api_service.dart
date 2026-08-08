import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static String backendUrl = kIsWeb 
      ? "http://127.0.0.1:8000" 
      : (Platform.isAndroid ? "http://10.0.2.2:8000" : "http://127.0.0.1:8000");



  static void setBackendUrl(String newUrl) {
    if (newUrl.endsWith('/')) {
      backendUrl = newUrl.substring(0, newUrl.length - 1);
    } else {
      backendUrl = newUrl;
    }
  }

  /// Sends extracted raw text to the AI endpoint to process summaries, proposals, or insights.
  static Future<Map<String, dynamic>> processText({
    required String text,
    required String action,
    required String userTier,
    required String userId,
  }) async {
    final uri = Uri.parse("$backendUrl/api/ai/process");
    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "action": action,
          "user_tier": userTier,
          "user_id": userId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Internal Server Error';
        throw HttpException(errorMsg.toString());
      }
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException("Connection error: Could not reach Vaultly Server at $backendUrl. Details: $e");
    }
  }

  /// Uploads binary files to the backend fallback parser and returns the extracted text string.
  static Future<String> parseFallback(Uint8List bytes, String filename) async {
    final uri = Uri.parse("$backendUrl/api/files/extract-fallback");
    try {
      final request = http.MultipartRequest("POST", uri);
      
      final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';
      
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
      final responseStream = await request.send();
      final response = await http.Response.fromStream(responseStream);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['extracted_text'] ?? '';
      } else {
        final errorMsg = jsonDecode(response.body)['detail'] ?? 'Failed to parse file on server.';
        throw HttpException(errorMsg.toString());
      }
    } on HttpException {
      rethrow;
    } catch (e) {
      throw HttpException("Connection error: Could not reach fallback parser at $backendUrl. Details: $e");
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}
