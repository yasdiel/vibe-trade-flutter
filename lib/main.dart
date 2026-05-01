import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/services/product_service.dart';
import 'package:vibe_trade_v1/services/service_service.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/services/theme_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import './routes/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  env.load();
  await ThemeService.hydrate();
  await StoreService.hydrate();
  await ProductService.hydrate();
  await ServiceService.hydrate();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.modeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'VibeTrade',
          theme: AppTheme.buildLightTheme(),
          darkTheme: AppTheme.buildDarkTheme(),
          themeMode: mode == AppThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/',
          routes: getApplicationRoutes(),
        );
      },
    );
  }
}
