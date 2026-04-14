import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../auth/login_page.dart';
import 'main_shell.dart';

class KampusApp extends StatefulWidget {
  const KampusApp({super.key});

  @override
  State<KampusApp> createState() => _KampusAppState();
}

class _KampusAppState extends State<KampusApp> {
  ThemeMode themeMode = ThemeMode.system;
  bool authenticated = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kampusapp',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: authenticated
          ? MainShell(
              themeMode: themeMode,
              onThemeChanged: (mode) => setState(() => themeMode = mode),
              onLogout: () => setState(() => authenticated = false),
            )
          : LoginPage(onLogin: () => setState(() => authenticated = true)),
    );
  }
}
