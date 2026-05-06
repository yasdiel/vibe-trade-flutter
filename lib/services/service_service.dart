import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/catalog/catalog_service_json.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/models/service_model.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/services/store_service.dart';

/// Catálogo de servicios contra `POST …/stores/{id}/detail` y `PUT/DELETE …/services/…`.
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

  static Future<void> refreshFromServer(String storeId) async {
    await hydrate();
    final sid = storeId.trim();
    if (sid.isEmpty) return;

    final root = await MarketService.fetchStoreCatalogDetailDecoded(sid);
    final catalog = root['catalog'];
    if (catalog is! Map<String, dynamic>) return;

    final rawList = catalog['services'];
    if (rawList is! List) return;

    final parsed =
        rawList.whereType<Map>().map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return CatalogServiceJson.fromApiMap(m);
        }).where((s) => s.id.isNotEmpty).toList();

    servicesNotifier.value = <ServiceModel>[
      ...servicesNotifier.value.where((s) => s.storeId != sid),
      ...parsed,
    ];
    await _persist();
    await _syncStoreCount(sid);
  }

  static Future<List<String>> _uploadResolvedPaths(List<String> paths) async {
    final out = <String>[];
    for (final p in paths) {
      final t = p.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('http://') ||
          t.startsWith('https://') ||
          t.startsWith('/api/')) {
        out.add(t);
        continue;
      }
      try {
        final f = File(t);
        if (f.existsSync()) {
          out.add(await MediaService.uploadAvatar(f));
        }
      } catch (_) {}
    }
    return out;
  }

  static Future<ServiceModel> createServiceViaApi({
    required String storeId,
    required String category,
    required String serviceType,
    required List<ProductCurrency> acceptedCurrencies,
    required String description,
    required bool hasRisks,
    required String risks,
    required String includes,
    required String excludes,
    required bool hasDependencies,
    required String dependencies,
    required String delivery,
    required bool hasWarranty,
    required String warranty,
    required String intellectualProperty,
    required List<String> imagePaths,
  }) async {
    await hydrate();
    final id = _generateId();
    final uploaded = await _uploadResolvedPaths(imagePaths);
    final urls = List<String>.unmodifiable(uploaded);

    if (urls.isEmpty) {
      throw StateError('Se requiere al menos una foto subida.');
    }

    final draft = ServiceModel(
      id: id,
      storeId: storeId,
      category: category.trim(),
      serviceType: serviceType.trim(),
      acceptedCurrencies: List<ProductCurrency>.unmodifiable(
        acceptedCurrencies.toSet(),
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
      imagePaths: urls,
      createdAt: DateTime.now(),
      published: false,
    );

    final body = CatalogServiceJson.toUpsertBody(
      draft,
      published: false,
    );

    await MarketService.putStoreService(
      storeId: storeId,
      serviceId: id,
      body: body,
    );
    await refreshFromServer(storeId);
    return getById(id) ?? draft;
  }

  static Future<ServiceModel> updateServiceViaApi(
    String id, {
    required String storeId,
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
    final existing = getById(id);
    if (existing == null) throw StateError('Servicio no encontrado');

    final nh = hasRisks ?? existing.hasRisks;
    final ndep = hasDependencies ?? existing.hasDependencies;
    final nw = hasWarranty ?? existing.hasWarranty;

    List<String>? newPaths;
    if (imagePaths != null) {
      newPaths = await _uploadResolvedPaths(imagePaths);
      if (newPaths.isEmpty) {
        throw StateError('Sin fotos válidas después de procesar rutas locales.');
      }
    }

    final next = existing.copyWith(
      category: category?.trim(),
      serviceType: serviceType?.trim(),
      acceptedCurrencies: acceptedCurrencies,
      description: description?.trim(),
      hasRisks: nh,
      risks:
          !nh
              ? ''
              : (risks != null ? risks.trim() : existing.risks),
      includes: includes?.trim(),
      excludes: excludes?.trim(),
      hasDependencies: ndep,
      dependencies:
          !ndep
              ? ''
              : (dependencies != null ? dependencies.trim() : existing.dependencies),
      delivery: delivery?.trim(),
      hasWarranty: nw,
      warranty:
          !nw
              ? ''
              : (warranty != null ? warranty.trim() : existing.warranty),
      intellectualProperty: intellectualProperty?.trim(),
      imagePaths: newPaths,
    );

    final body = CatalogServiceJson.toUpsertBody(
      next,
      published: existing.published,
    );

    await MarketService.putStoreService(
      storeId: storeId,
      serviceId: id,
      body: body,
    );
    await refreshFromServer(storeId);
    return getById(id) ?? next;
  }

  static Future<ServiceModel> publishService(
    String storeId,
    String serviceId,
  ) async {
    await hydrate();
    final existing = getById(serviceId);
    if (existing == null || existing.storeId != storeId) {
      throw StateError('Servicio no encontrado');
    }
    final body = CatalogServiceJson.toUpsertBody(
      existing,
      published: true,
    );
    await MarketService.putStoreService(
      storeId: storeId,
      serviceId: serviceId,
      body: body,
    );
    await refreshFromServer(storeId);
    return getById(serviceId) ?? existing.copyWith(published: true);
  }

  static Future<void> deleteService(String id) async {
    await hydrate();
    final removed = getById(id);
    final sid = removed?.storeId.trim() ?? '';

    if (removed != null && sid.isNotEmpty) {
      await MarketService.deleteStoreService(storeId: sid, serviceId: id);
      await refreshFromServer(sid);
    } else {
      servicesNotifier.value = servicesNotifier.value
          .where((service) => service.id != id)
          .toList(growable: false);
      await _persist();
    }

    if (removed != null && removed.storeId.isNotEmpty) {
      await _syncStoreCount(removed.storeId);
    }
  }

  static Future<void> deleteAllForStore(String storeId) async {
    await hydrate();
    final ours =
        servicesNotifier.value.where((s) => s.storeId == storeId).toList();

    for (final s in ours) {
      try {
        await MarketService.deleteStoreService(
          storeId: storeId,
          serviceId: s.id,
        );
      } catch (_) {
        debugPrint('[ServiceService] deleteAll omitido ${s.id}');
      }
    }
    servicesNotifier.value =
        servicesNotifier.value
            .where((service) => service.storeId != storeId)
            .toList(growable: false);
    await _persist();
    await _syncStoreCount(storeId);
  }

  static Future<void> _syncStoreCount(String storeId) async {
    final count =
        servicesNotifier.value.where((s) => s.storeId == storeId).length;
    if (StoreService.getById(storeId) == null) return;
    try {
      await StoreService.updateStore(storeId, servicesCount: count);
    } catch (_) {}
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      servicesNotifier.value.map((s) => s.toJson()).toList(),
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
