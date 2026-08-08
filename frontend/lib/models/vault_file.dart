import 'dart:convert';
import 'dart:typed_data';

class VaultFile {
  final String id;
  final String name;
  final String filePath;
  final int fileSize;
  final String extractedText;
  String? summary;
  String? proposal;
  List<String>? insights;
  final DateTime createdAt;
  
  // Non-serialized in-memory raw bytes cache
  Uint8List? fileBytes;

  VaultFile({
    required this.id,
    required this.name,
    required this.filePath,
    required this.fileSize,
    required this.extractedText,
    this.summary,
    this.proposal,
    this.insights,
    required this.createdAt,
    this.fileBytes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'fileSize': fileSize,
      'extractedText': extractedText,
      'summary': summary,
      'proposal': proposal,
      'insights': insights,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VaultFile.fromMap(Map<String, dynamic> map) {
    return VaultFile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      filePath: map['filePath'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      extractedText: map['extractedText'] ?? '',
      summary: map['summary'],
      proposal: map['proposal'],
      insights: map['insights'] != null ? List<String>.from(map['insights']) : null,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory VaultFile.fromJson(String source) => VaultFile.fromMap(json.decode(source));
}
