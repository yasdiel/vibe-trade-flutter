import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/models/service_model.dart';
import 'package:vibe_trade_v1/services/store_service.dart';

/// Mock catalog of services. Each service belongs to a store via [storeId].
/// Persists to [SharedPreferences] and keeps the parent store's
/// [StoreModel.servicesCount] in sync automatically.
class ServiceService {
  static const String _servicesKey = 'simulated_services';

  static final ValueNotifier<List<ServiceModel>> servicesNotifier =
      ValueNotifier<List<ServiceModel>>(<ServiceModel>[]);

  static bool _hydrated = false;

  static Future<void> hydrate() async {
    if (_hydrated) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_servicesKey);
    servicesNotifier.value = _decode(raw);
    _hydrated = true;
  }

  static List<ServiceModel> servicesForStore(String storeId) {
    return servicesNotifier.value
        .where((service) => service.storeId == storeId)
        .toList(growable: false);
  }

  static ServiceModel? getById(String id) {
    for (final service in servicesNotifier.value) {
      if (service.id == id) return service;
    }
    return null;
  }

  static Future<ServiceModel> createService({
    required String storeId,
    required String category,
    required String serviceType,
    required List<ProductCurrency> acceptedCurrencies,
    required String description,
    required bool hasRisks,
    String risks = '',
    String includes = '',
    String excludes = '',
    bool hasDependencies = false,
    String dependencies = '',
    String delivery = '',
    bool hasWarranty = false,
    String warranty = '',
    String intellectualProperty = '',
    required List<String> imagePaths,
  }) async {
    await hydrate();
    final service = ServiceModel(
      id: _generateId(),
      storeId: storeId,
      category: category.trim(),
      serviceType: serviceType.trim(),
      acceptedCurrencies: List<ProductCurrency>.unmodifiable(
        acceptedCurrencies,
      ),
      description: description.trim(),
      hasRisks: hasRisks,
      risks: hasRisks ? risks.trim() : '',
      includes: includes.trim(),
      excludes: excludes.trim(),
      hasDependencies: hasDependencies,
      dependencies: hasDependencies ? dependencies.trim() : '',
      delivery: delivery.trim(),
      hasWarranty: hasWarranty,
      warranty: hasWarranty ? warranty.trim() : '',
      intellectualProperty: intellectualProperty.trim(),
      imagePaths: List<String>.unmodifiable(imagePaths),
      createdAt: DateTime.now(),
    );
    servicesNotifier.value = <ServiceModel>[
      ...servicesNotifier.value,
      service,
    ];
    await _persist();
    await _syncStoreCount(storeId);
    return service;
  }

  static Future<ServiceModel> updateService(
    String id, {
    String? category,
    String? serviceType,
    List<ProductCurrency>? acceptedCurrencies,
    String? description,
    bool? hasRisks,
    String? risks,
    String? includes,
    String? excludes,
    bool? hasDependencies,
    String? dependencies,
    String? delivery,
    bool? hasWarranty,
    String? warranty,
    String? intellectualProperty,
    List<String>? imagePaths,
  }) async {
    await hydrate();
    final list = <ServiceModel>[...servicesNotifier.value];
    final index = list.indexWhere((service) => service.id == id);
    if (index == -1) {
      throw StateError('Servicio no encontrado');
    }

    final current = list[index];
    final newHasRisks = hasRisks ?? current.hasRisks;
    final newHasDependencies = hasDependencies ?? current.hasDependencies;
    final newHasWarranty = hasWarranty ?? current.hasWarranty;

    final updated = current.copyWith(
      category: category?.trim(),
      serviceType: serviceType?.trim(),
      acceptedCurrencies: acceptedCurrencies != null
          ? List<ProductCurrency>.unmodifiable(acceptedCurrencies)
          : null,
      description: description?.trim(),
      hasRisks: newHasRisks,
      risks: !newHasRisks ? '' : risks?.trim(),
      includes: includes?.trim(),
      excludes: excludes?.trim(),
      hasDependencies: newHasDependencies,
      dependencies: !newHasDependencies ? '' : dependencies?.trim(),
      delivery: delivery?.trim(),
      hasWarranty: newHasWarranty,
      warranty: !newHasWarranty ? '' : warranty?.trim(),
      intellectualProperty: intellectualProperty?.trim(),
      imagePaths: imagePaths != null
          ? List<String>.unmodifiable(imagePaths)
          : null,
    );
    list[index] = updated;
    servicesNotifier.value = list;
    await _persist();
    return updated;
  }

  static Future<void> deleteService(String id) async {
    await hydrate();
    final removed = getById(id);
    servicesNotifier.value = servicesNotifier.value
        .where((service) => service.id != id)
        .toList(growable: false);
    await _persist();
    if (removed != null) {
      await _syncStoreCount(removed.storeId);
    }
  }

  static Future<void> deleteAllForStore(String storeId) async {
    await hydrate();
    servicesNotifier.value = servicesNotifier.value
        .where((service) => service.storeId != storeId)
        .toList(growable: false);
    await _persist();
    await _syncStoreCount(storeId);
  }

  static Future<void> _syncStoreCount(String storeId) async {
    final count = servicesNotifier.value
        .where((service) => service.storeId == storeId)
        .length;
    if (StoreService.getById(storeId) == null) return;
    try {
      await StoreService.updateStore(storeId, servicesCount: count);
    } catch (_) {
      // Si la tienda fue eliminada en paralelo, no propagamos el error.
    }
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      servicesNotifier.value.map((service) => service.toJson()).toList(),
    );
    await prefs.setString(_servicesKey, encoded);
  }

  static List<ServiceModel> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <ServiceModel>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ServiceModel>[];
      return decoded
          .whereType<Map>()
          .map((map) => ServiceModel.fromJson(Map<String, dynamic>.from(map)))
          .toList(growable: false);
    } catch (_) {
      return const <ServiceModel>[];
    }
  }

  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(0xFFFF);
    return '$timestamp-${random.toRadixString(16)}';
  }
}
