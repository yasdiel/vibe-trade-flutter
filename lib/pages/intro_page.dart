import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/widgets/intro_btn.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: Image.asset('assets/images/logo.png')),
            IntroBtn(
              text: 'Registrarme',
              onTap: () {
                Navigator.pushReplacementNamed(context, '/signup');
              },
            ),
            SizedBox(height: 20),
            IntroBtn(
              text: 'Iniciar Sesion',
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
