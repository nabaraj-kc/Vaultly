import 'package:flutter/material.dart';
import '../core/theme_manager.dart';
import '../core/app_state.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';


class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  int _cachedFilesCount = 0;

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

  void _changeTheme(ThemeMode? mode) {
    if (mode == null) return;
    setState(() {
      themeManager.setThemeMode(mode);
    });
  }

  Future<void> _saveSettings() async {
    ApiService.setBackendUrl(_urlController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Backend URL saved successfully!"),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _clearCache() async {
    await CacheService.clearCache();
    await _loadStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Local cache cleared successfully."),
        backgroundColor: Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = themeManager.themeMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SETTINGS"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader("Account Status"),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: appState,
            builder: (context, _) {
              final isPro = appState.userTier == "pro";
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E2E38).withOpacity(0.5)),
                ),
                child: SwitchListTile(
                  title: const Text("PRO Access Tier"),
                  subtitle: Text(isPro ? "Unlimited requests & dynamic failovers active" : "Limited to 3 daily credits"),
                  value: isPro,
                  onChanged: (val) {
                    appState.setTier(val ? "pro" : "free");
                  },
                  activeColor: const Color(0xFF6366F1),
                ),
              );
            }
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Appearance"),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2E2E38).withOpacity(0.5)),
            ),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text("Light Mode"),
                  value: ThemeMode.light,
                  groupValue: currentThemeMode,
                  onChanged: _changeTheme,
                  activeColor: const Color(0xFF6366F1),
                ),
                const Divider(height: 1, color: Color(0xFF2E2E38)),
                RadioListTile<ThemeMode>(
                  title: const Text("Dark Mode"),
                  value: ThemeMode.dark,
                  groupValue: currentThemeMode,
                  onChanged: _changeTheme,
                  activeColor: const Color(0xFF6366F1),
                ),
                const Divider(height: 1, color: Color(0xFF2E2E38)),
                RadioListTile<ThemeMode>(
                  title: const Text("System Default"),
                  value: ThemeMode.system,
                  groupValue: currentThemeMode,
                  onChanged: _changeTheme,
                  activeColor: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Connection Settings"),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: "FastAPI Backend URL",
              prefixIcon: Icon(Icons.link, color: Color(0xFF6366F1)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text("Save URL"),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("API Keys"),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Custom Gemini API Key (Bypasses Limit)",
              prefixIcon: Icon(Icons.vpn_key, color: Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Cache Storage"),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage, color: Color(0xFF9CA3AF)),
              title: const Text("Clear Document Cache"),
              subtitle: Text("Currently caching $_cachedFilesCount parsed files"),
              trailing: TextButton(
                onPressed: _clearCache,
                child: const Text("Clear All", style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6366F1),
        letterSpacing: 0.5,
      ),
    );
  }
}
