import 'dart:io';
import 'dart:typed_data';
import 'package:mime/mime.dart';

class ExtractorService {
  static Future<String> extractTextLocally(Uint8List bytes, String filename) async {
    final path = filename.toLowerCase();

    if (path.endsWith('.txt')) {
      return _extractTxt(bytes);
    } else {
      // For PDF, DOCX, and other complex files, we rely on backend fallback parsing
      throw UnsupportedError("Requires backend fallback parsing");
    }
  }

  static String _extractTxt(Uint8List bytes) {
    try {
      return String.fromCharCodes(bytes);
    } catch (e) {
      throw FormatException("Failed to decode text file: $e");
    }
  }

  /// Custom light-weight Dart PDF content-stream text extractor.
  /// Parses the PDF structure and grabs raw ASCII strings inside stream brackets.
  static String _extractPdfTextLocally(Uint8List bytes) {
    try {
      final buffer = StringBuffer();
      final content = String.fromCharCodes(bytes);
      
      // Look for PDF content streams (usually located between "stream" and "endstream" blocks)
      final streamRegex = RegExp(r'stream[\r\n]+([\s\S]*?)[\r\n]+endstream', multiLine: true);
      final matches = streamRegex.allMatches(content);
      
      for (final match in matches) {
        final streamData = match.group(1);
        if (streamData == null) continue;
        
        // Find text block bracket patterns in PDF syntax: (Text string) Tj or TJ
        // PDF strings are enclosed in parentheses ( )
        final textRegex = RegExp(r'\(([^)]+)\)');
        final textMatches = textRegex.allMatches(streamData);
        
        for (final textMatch in textMatches) {
          final literalText = textMatch.group(1);
          if (literalText != null) {
            // Filter out internal PDF coordinate spacing/tokens
            if (literalText.length > 1 && !literalText.startsWith('/') && !_isPdfControlToken(literalText)) {
              buffer.write('$literalText ');
            }
          }
        }
      }
      
      final result = buffer.toString().trim();
      
      // If client-side stream parsing failed to produce substantial content (e.g. compressed streams),
      // we flag it to run on the backend fallback API instead.
      if (result.length < 30) {
        throw UnsupportedError("PDF content stream is compressed or scanned. Fallback required.");
      }
      
      return _sanitizePdfText(result);
    } catch (e) {
      // Re-raise UnsupportedError so the UI is informed that a backend fallback is needed
      if (e is UnsupportedError) rethrow;
      throw UnsupportedError("Local extraction failed: ${e.toString()}. Requesting backend fallback.");
    }
  }

  static bool _isPdfControlToken(String token) {
    // Avoid capturing hex fonts mappings or page structures
    return token.contains(RegExp(r'^[0-9a-fA-F\s]+$')) && token.length > 15;
  }

  static String _sanitizePdfText(String raw) {
    // Remove typical PDF layout control escapes
    return raw
        .replaceAll(r'\)', ')')
        .replaceAll(r'\(', '(')
        .replaceAll(r'\\', r'\')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
