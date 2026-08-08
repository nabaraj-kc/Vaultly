import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vault_file.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../core/app_state.dart';
import 'pdf_preview_widget.dart';

class FileViewerView extends StatefulWidget {
  final VaultFile vaultFile;

  const FileViewerView({
    Key? key,
    required this.vaultFile,
  }) : super(key: key);

  @override
  State<FileViewerView> createState() => _FileViewerViewState();
}

class _FileViewerViewState extends State<FileViewerView> with TickerProviderStateMixin {
  late TabController _tabController;
  late VaultFile _currentFile;
  bool _isSummarizeOn = false;
  bool _isLoading = false;
  
  // Chat state parameters
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isChatLoading = false;

  // Animation controller profiles
  late AnimationController _fadeController;
  late Animation<double> _cardOpacity;
  late Animation<Offset> _cardSlide;
  
  // Staggered trigger offsets
  bool _showKeyTakeaways = false;
  bool _showInsights = false;

  // Bytes loader parameters
  Uint8List? _fileBytes;
  bool _loadingBytes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentFile = widget.vaultFile;
    _fileBytes = _currentFile.fileBytes;
    
    // Check if summary already exists to set default toggle
    if (_currentFile.summary != null) {
      _isSummarizeOn = true;
      _showKeyTakeaways = true;
      _showInsights = true;
    }

    // Initialize animation drivers
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    if (_isSummarizeOn) {
      _fadeController.forward();
    }

    _loadBytesIfNeeded();
  }

  Future<void> _loadBytesIfNeeded() async {
    if (_fileBytes != null) return;
    if (kIsWeb) return;
    
    setState(() {
      _loadingBytes = true;
    });

    try {
      final file = File(_currentFile.filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(() {
          _fileBytes = bytes;
          _currentFile.fileBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error loading file bytes locally: $e");
    } finally {
      setState(() {
        _loadingBytes = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _toggleSummarize(bool value) async {
    setState(() {
      _isSummarizeOn = value;
    });

    if (value) {
      // Auto-switch to Summary tab
      _tabController.animateTo(1);
      
      if (_currentFile.summary == null) {
        await _fetchSummary();
      } else {
        _fadeController.reset();
        _fadeController.forward();
      }
    }
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _showKeyTakeaways = false;
      _showInsights = false;
    });

    try {
      final response = await ApiService.processText(
        text: _currentFile.extractedText,
        action: "summarize",
        userTier: appState.userTier,
        userId: "user_device_id_123",
      );

      final resultText = response['result'] as String;

      // Extract details for secondary insights (e.g. OCR fallback parsing)
      final insightsResponse = await ApiService.processText(
        text: _currentFile.extractedText,
        action: "insights",
        userTier: appState.userTier,
        userId: "user_device_id_123",
      );

      final cardsList = _parseInsightCards(insightsResponse['result'] as String);

      setState(() {
        _currentFile.summary = resultText;
        _currentFile.insights = cardsList;
      });

      await CacheService.saveFile(_currentFile);

      // Trigger staggered animations
      _fadeController.reset();
      _fadeController.forward();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _showKeyTakeaways = true);
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showInsights = true);
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI Failed: $e"), backgroundColor: const Color(0xFFEF4444)),
      );
      setState(() {
        _isSummarizeOn = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _parseInsightCards(String rawOutput) {
    final List<String> cards = [];
    final rawSplits = rawOutput.split(RegExp(r'CARD \d+:?'));
    for (var split in rawSplits) {
      final clean = split.trim();
      if (clean.isNotEmpty) {
        cards.add(clean);
      }
    }
    return cards.isEmpty ? [rawOutput] : cards;
  }

  Future<void> _sendChatMessage() async {
    final question = _chatController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _chatMessages.add({"role": "user", "text": question});
      _chatController.clear();
      _isChatLoading = true;
    });

    try {
      // Create a contextual prompt including raw file context
      final contextPayload = 
          "Context Document:\n\"\"\"\n${_currentFile.extractedText}\n\"\"\"\n\n"
          "Answer this user question strictly based on the context above: $question";

      final response = await ApiService.processText(
        text: contextPayload,
        action: "chat",
        userTier: appState.userTier,
        userId: "user_device_id_123",
      );

      setState(() {
        _chatMessages.add({"role": "assistant", "text": response['result'] ?? ""});
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({"role": "error", "text": "Failed to connect to AI server: $e"});
      });
    } finally {
      setState(() {
        _isChatLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard!"), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentFile.name, style: const TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          tabs: const [
            Tab(text: "Preview"),
            Tab(text: "Summary"),
            Tab(text: "Chat"),
            Tab(text: "Insights"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreviewTab(),
                _buildSummaryTab(),
                _buildChatTab(),
                _buildInsightsTab(),
              ],
            ),
          ),
          _buildBottomActionToggle(),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    final isPdf = _currentFile.name.toLowerCase().endsWith('.pdf');
    
    if (isPdf && _fileBytes != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              "Interactive Original Document View (${(_currentFile.fileSize / 1024).toStringAsFixed(1)} KB)",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
            ),
          ),
          Expanded(
            child: PdfPreviewWidget(
              bytes: _fileBytes!,
              filename: _currentFile.name,
            ),
          ),
        ],
      );
    }

    if (isPdf && _loadingBytes) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currentFile.name.split('.').last.toUpperCase(),
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Document Source Text Preview",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E2E38).withOpacity(0.5)),
            ),
            child: Text(
              _currentFile.extractedText.isNotEmpty 
                  ? _currentFile.extractedText 
                  : "No extractable text content found.",
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (!_isSummarizeOn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt, size: 64, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 16),
            const Text("AI Summary is inactive", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              "Toggle '✨ Summarize' below to extract AI insights.",
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _toggleSummarize(true),
              child: const Text("Summarize Now"),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (_currentFile.summary == null) {
      return const Center(child: Text("Empty summary outcome."));
    }

    return FadeTransition(
      opacity: _cardOpacity,
      child: SlideTransition(
        position: _cardSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryHeaderBlock(),
              const SizedBox(height: 20),
              _buildStaggeredKeyTakeaways(),
              const SizedBox(height: 20),
              _buildStaggeredInsightsBlock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeaderBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E24), Color(0xFF252530)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
              const SizedBox(width: 8),
              Text(
                "Executive Summary",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MarkdownBody(
            data: _currentFile.summary!,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(color: Color(0xFFF3F4F6), fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaggeredKeyTakeaways() {
    return AnimatedOpacity(
      opacity: _showKeyTakeaways ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2E2E38).withOpacity(0.5)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Key Takeaways",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6366F1)),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Primary objectives focus on scaling file indexing services client-side.",
                    style: TextStyle(fontSize: 13, color: Color(0xFFF3F4F6)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Backend components leverage Pydantic models for fast structured routing.",
                    style: TextStyle(fontSize: 13, color: Color(0xFFF3F4F6)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredInsightsBlock() {
    return AnimatedOpacity(
      opacity: _showInsights ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1B4B),
              side: const BorderSide(color: Color(0xFF4F46E5)),
            ),
            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF6366F1)),
            label: const Text("Copy Summary", style: TextStyle(fontSize: 13, color: Color(0xFFC7D2FE))),
            onPressed: () => _copyToClipboard(_currentFile.summary!),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF064E3B),
              side: const BorderSide(color: Color(0xFF10B981)),
            ),
            icon: const Icon(Icons.share, size: 16, color: Color(0xFF10B981)),
            label: const Text("Share Card", style: TextStyle(fontSize: 13, color: Color(0xFFA7F3D0))),
            onPressed: () => Share.share(_currentFile.summary!),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Container(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerItem(height: 24, width: 140),
          const SizedBox(height: 16),
          _buildShimmerItem(height: 120, width: double.infinity),
          const SizedBox(height: 20),
          _buildShimmerItem(height: 20, width: 100),
          const SizedBox(height: 12),
          _buildShimmerItem(height: 60, width: double.infinity),
        ],
      ),
    );
  }

  Widget _buildShimmerItem({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF2E2E38).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, size: 48, color: const Color(0xFF9CA3AF).withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        "Ask any question about this document",
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final message = _chatMessages[index];
                    final isUser = message["role"] == "user";
                    final isError = message["role"] == "error";
                    
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser 
                              ? const Color(0xFF6366F1) 
                              : (isError ? const Color(0xFF7F1D1D) : Theme.of(context).cardColor),
                          borderRadius: BorderRadius.circular(16),
                          border: isUser ? null : Border.all(color: const Color(0xFF2E2E38)),
                        ),
                        child: Text(
                          message["text"] ?? "",
                          style: TextStyle(
                            color: isUser ? Colors.white : const Color(0xFFF3F4F6),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_isChatLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).cardColor,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: const InputDecoration(
                    hintText: "Type a question...",
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF6366F1)),
                onPressed: _sendChatMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsTab() {
    if (_currentFile.insights == null || _currentFile.insights!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.share, size: 64, color: Color(0xFF3B82F6)),
            const SizedBox(height: 16),
            const Text("Insight cards are empty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              "Insights generate automatically during summaries.",
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _toggleSummarize(true),
              child: const Text("Generate Insights"),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      itemCount: _currentFile.insights!.length,
      itemBuilder: (context, index) {
        final cardText = _currentFile.insights![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFF6366F1).withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Insight Card ${index + 1}",
                        style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Color(0xFF9CA3AF)),
                          onPressed: () => _copyToClipboard(cardText),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, size: 18, color: Color(0xFF9CA3AF)),
                          onPressed: () => Share.share(cardText),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      cardText,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFFF3F4F6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActionToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 20),
              SizedBox(width: 8),
              Text(
                "✨ Summarize File",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          Switch(
            value: _isSummarizeOn,
            onChanged: _toggleSummarize,
            activeColor: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }
}
