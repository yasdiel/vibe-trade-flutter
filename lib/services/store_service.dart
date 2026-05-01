import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/services/product_service.dart';
import 'package:vibe_trade_v1/services/service_service.dart';

/// Mock service that simulates a stores backend while the real API is not
/// ready. Stores are persisted in [SharedPreferences] so they survive app
/// restarts and exposed reactively via [storesNotifier].
class StoreService {
  static const String _storesKey = 'simulated_stores';

  static final ValueNotifier<List<StoreModel>> storesNotifier =
      ValueNotifier<List<StoreModel>>(<StoreModel>[]);

  static bool _hydrated = false;

  static Future<void> hydrate() async {
    if (_hydrated) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storesKey);
    storesNotifier.value = _decodeStores(raw);
    _hydrated = true;
  }

  static List<StoreModel> get stores => storesNotifier.value;

  static StoreModel? getById(String id) {
    for (final store in storesNotifier.value) {
      if (store.id == id) return store;
    }
    return null;
  }

  static Future<StoreModel> createStore({
    required String name,
    required String description,
    required List<String> categories,
    required bool hasOwnTransport,
    required String website,
    double? latitude,
    double? longitude,
  }) async {
    await hydrate();
    final store = StoreModel(
      id: _generateId(),
      name: name.trim(),
      description: description.trim(),
      categories: List<String>.unmodifiable(categories),
      hasOwnTransport: hasOwnTransport,
      website: website.trim(),
      latitude: latitude,
      longitude: longitude,
      imagePath: '',
      createdAt: DateTime.now(),
      isVerified: false,
      trustScore: 80,
    );
    storesNotifier.value = <StoreModel>[...storesNotifier.value, store];
    await _persist();
    return store;
  }

  static Future<StoreModel> updateStore(
    String id, {
    String? name,
    String? description,
    List<String>? categories,
    bool? hasOwnTransport,
    String? website,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    String? imagePath,
    bool? isVerified,
    int? trustScore,
    int? productsCount,
    int? servicesCount,
  }) async {
    await hydrate();
    final list = <StoreModel>[...storesNotifier.value];
    final index = list.indexWhere((store) => store.id == id);
    if (index == -1) {
      throw StateError('Tienda no encontrada');
    }
    final updated = list[index].copyWith(
      name: name?.trim(),
      description: description?.trim(),
      categories: categories,
      hasOwnTransport: hasOwnTransport,
      website: website?.trim(),
      latitude: latitude,
      longitude: longitude,
      clearLocation: clearLocation,
      imagePath: imagePath,
      isVerified: isVerified,
      trustScore: trustScore,
      productsCount: productsCount,
      servicesCount: servicesCount,
    );
    list[index] = updated;
    storesNotifier.value = list;
    await _persist();
    return updated;
  }

  static Future<void> deleteStore(String id) async {
    await hydrate();
    final list = storesNotifier.value
        .where((store) => store.id != id)
        .toList(growable: false);
    storesNotifier.value = list;
    await _persist();
    // Limpia productos y servicios huerfanos asociados a esta tienda.
    await ProductService.deleteAllForStore(id);
    await ServiceService.deleteAllForStore(id);
  }

  static Future<void> clearAll() async {
    storesNotifier.value = const <StoreModel>[];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storesKey);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      storesNotifier.value.map((store) => store.toJson()).toList(),
    );
    await prefs.setString(_storesKey, encoded);
  }

  static List<StoreModel> _decodeStores(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <StoreModel>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <StoreModel>[];
      return decoded
          .whereType<Map>()
          .map((map) => StoreModel.fromJson(Map<String, dynamic>.from(map)))
          .toList(growable: false);
    } catch (_) {
      return const <StoreModel>[];
    }
  }

  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(0xFFFF);
    return '$timestamp-${random.toRadixString(16)}';
  }
}
