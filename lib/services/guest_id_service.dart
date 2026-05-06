import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Identificador estable para el backend (`GET …/Recommendations/guest` exige
/// `guestId` con longitud ≥ 8).
class GuestIdService {
  GuestIdService._();

  static const _key = 'vt_recommendations_guest_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key)?.trim();
    if (existing != null && existing.length >= 8) return existing;

    final suffix = List.generate(
      24,
      (_) => Random.secure().nextInt(16).toRadixString(16),
    ).join();
    final id = 'vtg_${DateTime.now().toUtc().microsecondsSinceEpoch}_$suffix';
    await prefs.setString(_key, id);
    return id;
  }
}
