import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/config/env.dart';
import './routes/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  env.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      initialRoute: '/',
      routes: getApplicationRoutes(),
    );
  }
}
