import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  int _cachedFilesCount = 0;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiService.backendUrl;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final list = await CacheService.loadCachedFiles();
    setState(() {
      _cachedFilesCount = list.length;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    ApiService.setBackendUrl(_urlController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Settings updated successfully!"),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _clearCache() async {
    await CacheService.clearCache();
    await _loadStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Local cache database cleared."),
        backgroundColor: Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SETTINGS"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionHeader("Connection Settings"),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "FastAPI Backend URL",
                hintText: "http://10.0.2.2:8000",
                prefixIcon: Icon(Icons.link, color: Color(0xFF4F46E5)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text("Save Backend URL"),
            ),
            const Divider(height: 36, color: Color(0xFF2E2E38)),
            
            _buildSectionHeader("Custom AI Credentials (Optional)"),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Custom Gemini API Key",
                hintText: "AIzaSy...",
                prefixIcon: Icon(Icons.vpn_key, color: Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Providing a custom API key allows you to bypass the freemium rate-limiting.",
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const Divider(height: 36, color: Color(0xFF2E2E38)),
            
            _buildSectionHeader("Account & Referral"),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.card_membership, color: Color(0xFF4F46E5)),
              title: Text("Current Tier: ${_isPro ? 'PRO' : 'FREE'}"),
              trailing: Switch(
                value: _isPro,
                activeColor: const Color(0xFF10B981),
                onChanged: (val) {
                  setState(() {
                    _isPro = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.people_alt, color: Color(0xFF6366F1)),
              title: const Text("Referral Program"),
              subtitle: const Text("Invite a friend to unlock 5 additional daily free summaries!"),
              trailing: IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF9CA3AF)),
                onPressed: () {
                  // Trigger referral share
                  // Share.share("Use Vaultly to summarize files instantly! Use my code: REF123");
                },
              ),
            ),
            const Divider(height: 36, color: Color(0xFF2E2E38)),

            _buildSectionHeader("Storage Management"),
            const SizedBox(height: 8),
            ListTile(
              tileColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.storage, color: Color(0xFF9CA3AF)),
              title: const Text("Cached Files"),
              subtitle: Text("$_cachedFilesCount items saved locally"),
              trailing: TextButton(
                onPressed: _clearCache,
                child: const Text("Clear All", style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6366F1),
        letterSpacing: 0.5,
      ),
    );
  }
}
