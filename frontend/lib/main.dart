import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'core/theme_manager.dart';
import 'views/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VaultlyApp());
}

class VaultlyApp extends StatelessWidget {
  const VaultlyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'Vaultly',
          debugShowCheckedModeBanner: false,
          theme: VaultlyTheme.lightTheme,
          darkTheme: VaultlyTheme.darkTheme,
          themeMode: themeManager.themeMode,
          home: const MainNavigation(),
        );
      },
    );
  }
}
