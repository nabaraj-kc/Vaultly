import 'package:flutter/material.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TOOLS"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "All Tools",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
          ),
          const SizedBox(height: 12),
          _buildToolRow(
            context,
            "Summarize Any File",
            "Get concise summary of any document.",
            Icons.summarize,
            const Color(0xFF8B5CF6),
          ),
          _buildToolRow(
            context,
            "AI Chat With File",
            "Chat and get answers from your file context.",
            Icons.forum,
            const Color(0xFF10B981),
          ),
          _buildToolRow(
            context,
            "Convert File",
            "Convert to PDF, DOCX, TXT and more.",
            Icons.change_circle,
            const Color(0xFFF59E0B),
          ),
          _buildToolRow(
            context,
            "Extract Text (OCR)",
            "Extract text from images or scanned PDFs.",
            Icons.document_scanner,
            const Color(0xFF3B82F6),
          ),
          _buildToolRow(
            context,
            "Create Proposal",
            "Generate professional proposals in seconds.",
            Icons.business_center,
            const Color(0xFFEF4444),
          ),
          _buildToolRow(
            context,
            "Resume Builder",
            "Create ATS-friendly resumes from document text.",
            Icons.badge,
            const Color(0xFF06B6D4),
          ),
          _buildToolRow(
            context,
            "Translate Document",
            "Translate text to multiple languages using AI.",
            Icons.translate,
            Colors.pink,
          ),
          _buildToolRow(
            context,
            "Compress File",
            "Reduce file size without losing quality.",
            Icons.compress,
            Colors.brown,
          ),
        ],
      ),
    );
  }

  Widget _buildToolRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
        onTap: () {
          // Trigger file picker selection
        },
      ),
    );
  }
}
