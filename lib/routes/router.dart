import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/pages/main_page.dart';
import 'package:vibe_trade_v1/pages/signup_page.dart';
import 'package:vibe_trade_v1/pages/signin_page.dart';
import '../pages/splash_screen.dart';
import '../pages/intro_page.dart';

Map<String, WidgetBuilder> getApplicationRoutes() {
  return <String, WidgetBuilder>{
    '/': (context) => SplashScreen(),
    '/intropage': (context) => IntroPage(),
    '/signin': (context) => SigninPage(),
    '/signup': (context) => SignUp(),
    '/home': (context) => MainPage(),
  };
}
