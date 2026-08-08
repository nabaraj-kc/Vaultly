import 'package:flutter/material.dart';
import 'home_view.dart';
import 'tools_view.dart';
import 'profile_view.dart';
import '../services/file_service.dart';
import '../models/vault_file.dart';
import '../services/extractor_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'file_viewer_view.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isLoading = false;

  final List<Widget> _screens = [
    const HomeView(),
    const ToolsView(), // ToolsView also doubles as list/actions screen
    const ToolsView(), 
    const ProfileView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _triggerQuickPick() async {
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

      // 1. Local extraction
      try {
        extractedText = await ExtractorService.extractTextLocally(picked.bytes, picked.name);
      } catch (e) {
        isFallbackUsed = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Parsing file via secure backend pipeline..."),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
        extractedText = await ApiService.parseFallback(picked.bytes, picked.name);
      }

      // 2. Cache file
      final vaultFile = VaultFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: picked.name,
        filePath: picked.path,
        fileSize: picked.size,
        extractedText: extractedText,
        createdAt: DateTime.now(),
      );

      await CacheService.saveFile(vaultFile);

      if (isFallbackUsed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File extracted successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }

      // Navigate to File Viewer View
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FileViewerView(vaultFile: vaultFile),
        ),
      );
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
    final activeTheme = Theme.of(context);
    
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 16),
                  Text("Uploading file securely...", style: TextStyle(color: Color(0xFF9CA3AF))),
                ],
              ),
            )
          : IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: activeTheme.cardColor,
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: const Color(0xFF9CA3AF),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_rounded, color: Color(0xFF6366F1)),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_rounded),
            activeIcon: Icon(Icons.folder_rounded, color: Color(0xFF6366F1)),
            label: "Files",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            activeIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF6366F1)),
            label: "Tools",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            activeIcon: Icon(Icons.person_rounded, color: Color(0xFF6366F1)),
            label: "Profile",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _triggerQuickPick,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
