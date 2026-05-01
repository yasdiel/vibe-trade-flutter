import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class ThemeService {
  static const String _prefsKey = 'app_theme_mode';
  static bool _hydrated = false;

  static Future<void> hydrate() async {
    if (_hydrated) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      AppTheme.modeNotifier.value = raw == 'dark'
          ? AppThemeMode.dark
          : AppThemeMode.light;
    } catch (_) {
      AppTheme.modeNotifier.value = AppThemeMode.light;
    } finally {
      _hydrated = true;
    }
  }

  static Future<void> setMode(AppThemeMode mode) async {
    AppTheme.modeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        mode == AppThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {
      // Si falla la persistencia ignoramos: el cambio en memoria ya ocurrio.
    }
  }

  static Future<void> toggle() async {
    await setMode(
      AppTheme.mode == AppThemeMode.light
          ? AppThemeMode.dark
          : AppThemeMode.light,
    );
  }
}
