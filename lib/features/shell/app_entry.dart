import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/supabase/supabase_service.dart';
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
  StreamSubscription? _authSubscription;
  bool _initialized = false;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAuth());
    _listenAuth();
  }

  Future<void> _checkAuth() async {
    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      await SupabaseService.loadCurrentProfileToAppState();
    }
    setState(() {
      _authenticated = session != null;
      _initialized = true;
    });
  }

  void _listenAuth() {
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      if (session != null) {
        await SupabaseService.loadCurrentProfileToAppState();
      } else {
        SupabaseService.resetAppProfile();
      }
      if (!mounted) return;
      setState(() {
        _authenticated = session != null;
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      key: ValueKey(_authenticated),
      debugShowCheckedModeBanner: false,
      title: 'G Kampüs',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: _authenticated
          ? MainShell(
              themeMode: themeMode,
              onThemeChanged: (mode) => setState(() => themeMode = mode),
              onLogout: () async {
                await SupabaseService.client.auth.signOut();
              },
            )
          : const LoginPage(),
    );
  }
}
