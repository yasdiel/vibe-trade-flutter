import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  Future<void> _loadApp() async {
    await Future.delayed(const Duration(seconds: 3));
    final isLoggedIn = await AuthService.hydrateSession();
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, isLoggedIn ? '/home' : '/intropage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Text(
          'VibeTrade',
          style: TextStyle(
            color: AppTheme.foregroundColor,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
