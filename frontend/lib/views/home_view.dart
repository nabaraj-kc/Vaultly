import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/vault_file.dart';
import '../services/file_service.dart';
import '../services/extractor_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../core/theme.dart';
import '../core/app_state.dart';
import 'file_viewer_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<VaultFile> _recentFiles = [];
  bool _isLoading = false;
  int _remainingCredits = 3;
  String _userTier = "free";

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final list = await CacheService.loadCachedFiles();
    setState(() {
      _recentFiles = list;
    });
  }

  Future<void> _pickAndProcess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final picked = await FileService.pickFile();
      if (picked == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String extractedText = "";
      bool isFallbackUsed = false;

      try {
        extractedText = await ExtractorService.extractTextLocally(picked.bytes, picked.name);
      } catch (e) {
        isFallbackUsed = true;
        extractedText = await ApiService.parseFallback(picked.bytes, picked.name);
      }

      final vaultFile = VaultFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: picked.name,
        filePath: picked.path,
        fileSize: picked.size,
        extractedText: extractedText,
        createdAt: DateTime.now(),
        fileBytes: picked.bytes, // Persist bytes in-memory for preview
      );

      await CacheService.saveFile(vaultFile);
      await _loadFiles();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileViewerView(vaultFile: vaultFile),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: const Color(0xFFEF4444)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6366F1)),
                    SizedBox(height: 16),
                    Text("Processing document...", style: TextStyle(color: Color(0xFF9CA3AF))),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    _buildUpgradeCreditsCard(),
                    const SizedBox(height: 24),
                    _buildQuickActionsHeader(),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 28),
                    _buildRecentFilesHeader(),
                    const SizedBox(height: 12),
                    _buildRecentFilesList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "VAULTLY",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: Color(0xFF6366F1),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: VaultlyTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.bolt, size: 16, color: Colors.white),
              SizedBox(width: 4),
              Text(
                "Pro",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E2E38).withOpacity(0.5)),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search files, tools or ask AI...",
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
          suffixIcon: Icon(Icons.mic, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildUpgradeCreditsCard() {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final remaining = appState.remainingCredits;
        final isPro = appState.userTier == "pro";
        
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF311042)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPro ? "Unlimited Power Active" : "Unlock Unlimited Power",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                isPro 
                    ? "You are on the PRO tier. Enjoy unlimited summaries and premium custom tools."
                    : "Go Pro for unlimited actions, larger files and advanced AI models.",
                style: const TextStyle(fontSize: 12, color: Color(0xFFC7D2FE)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? "PRO Account Active" : "Free Daily Credits: $remaining/3",
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 140,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: isPro ? 1.0 : remaining / 3,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            color: const Color(0xFF10B981),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isPro)
                    ElevatedButton(
                      onPressed: () {
                        appState.setTier("pro");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Simulated upgrade to PRO!"),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Upgrade Now", style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildQuickActionsHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "See All",
          style: TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: [
        _buildActionCard("Summarize\nAny File", Icons.summarize, const Color(0xFF8B5CF6), _pickAndProcess),
        _buildActionCard("AI Chat\nWith File", Icons.forum, const Color(0xFF10B981), _pickAndProcess),
        _buildActionCard("Convert\nFile", Icons.change_circle, const Color(0xFFF59E0B), _pickAndProcess),
        _buildActionCard("Extract\nText (OCR)", Icons.document_scanner, const Color(0xFF3B82F6), _pickAndProcess),
        _buildActionCard("Create\nProposal", Icons.business_center, const Color(0xFFEF4444), _pickAndProcess),
        _buildActionCard("Resume\nBuilder", Icons.badge, const Color(0xFF06B6D4), _pickAndProcess),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E38).withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Text(
              title,
              maxLines: 2,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFilesHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Recent Files",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          "See All",
          style: TextStyle(fontSize: 12, color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRecentFilesList() {
    if (_recentFiles.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          "No files uploaded yet. Tap '+' below to select a file.",
          style: TextStyle(color: const Color(0xFF9CA3AF).withOpacity(0.7), fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentFiles.length > 5 ? 5 : _recentFiles.length,
      itemBuilder: (context, index) {
        final vaultFile = _recentFiles[index];
        final fileExtension = vaultFile.name.split('.').last.toUpperCase();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getFileColor(fileExtension).withOpacity(0.2),
              child: Text(
                fileExtension,
                style: TextStyle(
                  color: _getFileColor(fileExtension),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            title: Text(
              vaultFile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              "${(vaultFile.fileSize / 1024).toStringAsFixed(1)} KB • Local Preview ready",
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FileViewerView(vaultFile: vaultFile),
                ),
              ).then((_) => _loadFiles());
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
