import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class VaultlyPickedFile {
  final String name;
  final int size;
  final Uint8List bytes;
  final String path;

  VaultlyPickedFile({
    required this.name,
    required this.size,
    required this.bytes,
    required this.path,
  });
}

class FileService {
  /// Launches the device file picker and extracts metadata + bytes safely across web and native platforms.
  static Future<VaultlyPickedFile?> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx'],
        withData: kIsWeb, // Forces bytes pre-loading on web
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      
      Uint8List bytes;
      String pathSimulated = "";

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception("File content is unavailable on this web browser session.");
        }
        bytes = file.bytes!;
        pathSimulated = file.name; // Simulating path using name on web
      } else {
        if (file.path == null) {
          throw Exception("Selected file path is null on this device.");
        }
        final ioFile = File(file.path!);
        bytes = await ioFile.readAsBytes();
        pathSimulated = file.path!;
      }

      return VaultlyPickedFile(
        name: file.name,
        size: file.size,
        bytes: bytes,
        path: pathSimulated,
      );
    } catch (e) {
      rethrow;
    }
  }
}
