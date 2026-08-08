import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vault_file.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class FileInsightsView extends StatefulWidget {
  final VaultFile vaultFile;
  final String userTier;
  final String userId;

  const FileInsightsView({
    Key? key,
    required this.vaultFile,
    required this.userTier,
    required this.userId,
  }) : super(key: key);

  @override
  State<FileInsightsView> createState() => _FileInsightsViewState();
}

class _FileInsightsViewState extends State<FileInsightsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;
  late VaultFile _currentFile;
  late String _currentTier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentFile = widget.vaultFile;
    _currentTier = widget.userTier;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _triggerAIAction(String action) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await ApiService.processText(
        text: _currentFile.extractedText,
        action: action,
        userTier: _currentTier,
        userId: widget.userId,
      );

      final resultText = response['result'] as String;

      setState(() {
        if (action == "summarize") {
          _currentFile.summary = resultText;
        } else if (action == "proposal") {
          _currentFile.proposal = resultText;
        } else if (action == "insights") {
          // Parse string into multiple cards if formatted by CARD 1, CARD 2, etc.
          _currentFile.insights = _parseInsightCards(resultText);
        }
      });

      // Update the local cache with the new intelligence
      await CacheService.saveFile(_currentFile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI processing complete!"),
          backgroundColor: Color(0xFF10B981),
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  List<String> _parseInsightCards(String rawOutput) {
    if (!rawOutput.contains("CARD")) {
      return [rawOutput];
    }
    
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard!"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareContent(String text) {
    Share.share(text, subject: "Insights from ${_currentFile.name}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentFile.name, style: const TextStyle(fontSize: 16)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4F46E5),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF9CA3AF),
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: "Summary"),
            Tab(icon: Icon(Icons.business_center), text: "Proposal"),
            Tab(icon: Icon(Icons.share), text: "Insights"),
          ],
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  SizedBox(height: 16),
                  Text("Synthesizing AI output...", style: TextStyle(color: Color(0xFF9CA3AF))),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildProposalTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildSummaryTab() {
    if (_currentFile.summary == null) {
      return _buildAISynthesisRequestWidget(
        action: "summarize",
        title: "Summarize Document",
        subtitle: "Generate an executive summary, core takeaways, and entity list.",
        icon: Icons.summarize_outlined,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: _currentFile.summary!,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Color(0xFFF3F4F6), fontSize: 14),
                    h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    h3: const TextStyle(color: Color(0xFF10B981), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text("Copy"),
                onPressed: () => _copyToClipboard(_currentFile.summary!),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text("Share"),
                onPressed: () => _shareContent(_currentFile.summary!),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProposalTab() {
    // Check tier: Free tier is locked from Proposals
    if (_currentTier != "pro") {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text(
                "Proposal Generator is PRO Only",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                "Generate structured client-ready proposals from raw text assets instantly.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Simulate upgrade to pro
                  setState(() {
                    _currentTier = "pro";
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Simulated Upgrade to PRO Success!"),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                child: const Text("Upgrade to PRO (Simulate)"),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentFile.proposal == null) {
      return _buildAISynthesisRequestWidget(
        action: "proposal",
        title: "Build Business Proposal",
        subtitle: "Compile project context into structured Problem, Solution, Scope, and Budget tables.",
        icon: Icons.business_center_outlined,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                child: MarkdownBody(
                  data: _currentFile.proposal!,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Color(0xFFF3F4F6), fontSize: 14),
                    h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text("Copy Proposal"),
                onPressed: () => _copyToClipboard(_currentFile.proposal!),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text("Share"),
                onPressed: () => _shareContent(_currentFile.proposal!),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_currentFile.insights == null || _currentFile.insights!.isEmpty) {
      return _buildAISynthesisRequestWidget(
        action: "insights",
        title: "Extract Insight Cards",
        subtitle: "Generate social media optimized summaries for Twitter, LinkedIn, and WhatsApp.",
        icon: Icons.share_outlined,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Shareable Insight Cards",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView.builder(
              itemCount: _currentFile.insights!.length,
              itemBuilder: (context, index) {
                final cardText = _currentFile.insights![index];
                return Card(
                  color: const Color(0xFF1E1E24),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: const Color(0xFF4F46E5).withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Card ${index + 1}",
                                style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 20, color: Color(0xFF9CA3AF)),
                                  onPressed: () => _copyToClipboard(cardText),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, size: 20, color: Color(0xFF9CA3AF)),
                                  onPressed: () => _shareContent(cardText),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              cardText,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Center(
            child: Text(
              "Swipe left / right to view more cards",
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAISynthesisRequestWidget({
    required String action,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF4F46E5)),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt, color: Color(0xFF10B981)),
              label: const Text("Generate with AI"),
              onPressed: () => _triggerAIAction(action),
            ),
          ],
        ),
      ),
    );
  }
}
