import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../models/vault_file.dart';
import '../services/extractor_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'file_insights.dart';
import 'settings.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<VaultFile> _recentFiles = [];
  bool _isLoading = false;
  int _remainingCredits = 3;
  String _userTier = "free";
  final String _userId = "user_device_id_123"; // Simulated device ID

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final files = await CacheService.loadCachedFiles();
    // Simulate loading tier and credits configuration from local storage
    setState(() {
      _recentFiles = files;
    });
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'docx'],
      );

      if (result == null || (result.files.single.bytes == null && result.files.single.path == null)) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final filename = result.files.single.name;
      final size = result.files.single.size;
      
      // Load bytes conditionally depending on web vs native platforms
      final Uint8List fileBytes = kIsWeb 
          ? result.files.single.bytes! 
          : await File(result.files.single.path!).readAsBytes();
      
      String extractedText = "";
      bool isFallbackUsed = false;

      // 1. Try Client-side local extraction
      try {
        extractedText = await ExtractorService.extractTextLocally(fileBytes, filename);
      } catch (e) {
        // Local parsing is unsupported/failed (e.g. DOCX, scanned PDF)
        // Fallback to backend API
        isFallbackUsed = true;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Parsing file via secure backend pipeline..."),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF4F46E5),
          ),
        );

        extractedText = await ApiService.parseFallback(fileBytes, filename);
      }

      // 2. Create the VaultFile record
      final vaultFile = VaultFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: filename,
        filePath: kIsWeb ? filename : result.files.single.path!,
        fileSize: size,
        extractedText: extractedText,
        createdAt: DateTime.now(),
      );

      // Save to cache
      await CacheService.saveFile(vaultFile);
      await _loadData();

      // Show processing status
      if (isFallbackUsed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File extracted successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      // Navigate to File Insights view to run AI actions
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileInsightsView(vaultFile: vaultFile, userTier: _userTier, userId: _userId),
        ),
      ).then((_) => _loadData());

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VAULTLY"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsView()),
              ).then((_) => _loadData());
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  SizedBox(height: 16),
                  Text("Analyzing document safely...", style: TextStyle(color: Color(0xFF9CA3AF))),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildQuotaMeter(),
                  const SizedBox(height: 24),
                  _buildUploadCard(),
                  const SizedBox(height: 28),
                  Text(
                    "Recent Documents",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildRecentFilesList()),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: _pickFile,
      ),
    );
  }

  Widget _buildQuotaMeter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E38)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFF10B981), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Free Daily Credits",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "$_remainingCredits / 3 actions",
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _remainingCredits / 3,
                  backgroundColor: const Color(0xFF16161C),
                  color: const Color(0xFF10B981),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xFF16161C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4F46E5).withOpacity(0.5),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.file_upload_outlined, size: 48, color: Color(0xFF4F46E5)),
              SizedBox(height: 12),
              Text(
                "Tap to select a document",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF3F4F6)),
              ),
              SizedBox(height: 4),
              Text(
                "Supports PDF, DOCX, TXT (Max 10MB)",
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFilesList() {
    if (_recentFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: const Color(0xFF9CA3AF).withOpacity(0.3)),
            const SizedBox(height: 12),
            const Text(
              "No documents processed yet",
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _recentFiles.length,
      itemBuilder: (context, index) {
        final vaultFile = _recentFiles[index];
        final fileExtension = vaultFile.name.split('.').last.toUpperCase();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getFileColor(fileExtension).withOpacity(0.2),
              child: Text(
                fileExtension,
                style: TextStyle(
                  color: _getFileColor(fileExtension),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              vaultFile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${(vaultFile.fileSize / 1024).toStringAsFixed(1)} KB • Local preview ready",
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileInsightsView(
                    vaultFile: vaultFile,
                    userTier: _userTier,
                    userId: _userId,
                  ),
                ),
              ).then((_) => _loadData());
            },
          ),
        );
      },
    );
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'PDF':
        return const Color(0xFFEF4444);
      case 'DOCX':
        return const Color(0xFF3B82F6);
      case 'TXT':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
