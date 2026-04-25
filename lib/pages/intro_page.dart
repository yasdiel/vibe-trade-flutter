import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/widgets/intro_btn.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      body: ResponsiveContent(
        maxWidth: isDesktop ? 520 : 360,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 8,
          vertical: 24,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: Image.asset('assets/images/logo.png')),
            const SizedBox(height: 24),
            IntroBtn(
              text: 'Registrarme',
              width: isDesktop ? double.infinity : 250,
              height: isDesktop ? 48 : 40,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
            ),
            const SizedBox(height: 20),
            IntroBtn(
              text: 'Iniciar Sesion',
              width: isDesktop ? double.infinity : 250,
              height: isDesktop ? 48 : 40,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/signin');
              },
            ),
          ],
        ),
      ),
    );
  }
}
