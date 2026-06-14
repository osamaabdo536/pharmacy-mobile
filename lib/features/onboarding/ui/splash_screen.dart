import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/local_storage.dart';

/// Shown briefly at app start while we check the saved token.
/// If a token exists, navigate to /home.
/// If not, GoRouter's redirect (in app.dart) sends us to /login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // TODO: later — validate token with Supabase
    // (Supabase.instance.client.auth.currentSession), not just check
    // it exists locally.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    if (TokenStorage.hasToken()) {
      context.go('/search');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}