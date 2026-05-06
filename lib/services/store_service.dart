import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/product_service.dart';
import 'package:vibe_trade_v1/services/service_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

/// Tiendas propias cargadas desde
/// **`GET /api/v1/Market/workspace/stores`** (lista relacional `{ "stores": {...} }`),
/// filtradas por `ownerUserId` del usuario actual. Alta/edición de perfil: ver
/// [MarketService.upsertWorkspaceStoreProfile] — **`PUT` el mismo path** —
/// no `POST /Market/stores` ni `PATCH` en rutas alternativas.
class StoreService {
  static const String _storesKey = 'simulated_stores';

  static final ValueNotifier<List<StoreModel>> storesNotifier =
      ValueNotifier<List<StoreModel>>(<StoreModel>[]);

  /// Mensaje de error al obtener tiendas desde el servidor. `null` si no hay
  /// fallo conocido tras el ultimo intento.
  static final ValueNotifier<String?> storesLoadErrorNotifier =
      ValueNotifier<String?>(null);

  static Future<void>? _refreshFuture;

  static Future<void> hydrate() async {
    await refreshStoresFromWorkspace();
  }

  /// Vuelve a cargar tiendas desde el servidor (Bearer token).
  static Future<void> refreshStoresFromWorkspace() async {
    _refreshFuture ??= _refreshStoresFromWorkspaceImpl().whenComplete(() {
      _refreshFuture = null;
    });
    await _refreshFuture;
  }

  static Future<void> _refreshStoresFromWorkspaceImpl() async {
    storesLoadErrorNotifier.value = null;

    final token = await SessionService.getSavedToken();
    if (token == null || token.trim().isEmpty) {
      storesNotifier.value = const <StoreModel>[];
      debugPrint('[StoreService] Sin token; lista de tiendas vacia.');
      storesLoadErrorNotifier.value = null;
      return;
    }

    try {
      final http.Response response = await MarketService.fetchWorkspaceStores();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        storesNotifier.value = const <StoreModel>[];
        storesLoadErrorNotifier.value = ApiResponseUtils.extractErrorMessage(
          response,
          fallback:
              'No se pudieron cargar las tiendas (HTTP ${response.statusCode}).',
        );
        debugPrint(
          '[StoreService] Workspace stores GET no OK: ${response.statusCode}',
        );
        return;
      }
      final user =
          SessionService.currentUserNotifier.value ??
          await SessionService.getSavedUser();
      final uid = user?.id.trim();
      if (uid == null || uid.isEmpty) {
        storesNotifier.value = const <StoreModel>[];
        debugPrint(
          '[StoreService] Usuario sin id en cache; lista vacia (carga el perfil).',
        );
        storesLoadErrorNotifier.value =
            'No encontramos datos de tu usuario para mostrar tus tiendas. Espera unos segundos o recarga usando el boton de actualizar en la parte superior.';
      } else {
        final list = storesFromWorkspaceResponseBody(
          response.body,
          restrictToOwnerUserId: uid,
        ).where((s) => s.id.trim().isNotEmpty).toList();
        storesNotifier.value = List<StoreModel>.unmodifiable(list);
        await _persist();
        storesLoadErrorNotifier.value = null;
      }
    } on Object catch (e, stack) {
      debugPrint('[StoreService] refreshStoresFromWorkspace fallo: $e');
      debugPrint('$stack');
      storesNotifier.value = const <StoreModel>[];
      storesLoadErrorNotifier.value = _messageForStoresLoadFailure(e);
    }
  }

  static String _messageForStoresLoadFailure(Object e) {
    if (e is UnauthorizedException) return e.message;
    return 'No pudimos cargar tus tiendas en este momento. Comprueba tu conexion al internet y usa el boton de actualizar (arriba a la derecha) o pulsa Reintentar aqui.';
  }

  /// Parsea JSON de `GET …/workspace/stores`.
  ///
  /// El backend suele incluir todas las tiendas del workspace global; si
  /// pasas [restrictToOwnerUserId] solo se listan tiendas donde
  /// `ownerUserId` coincide (tus tiendas).
  static List<StoreModel> storesFromWorkspaceResponseBody(
    String body, {
    String? restrictToOwnerUserId,
  }) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return const <StoreModel>[];
    try {
      final decoded = jsonDecode(trimmed);
      return _decodedWorkspaceStores(
        decoded,
        restrictToOwnerUserId: restrictToOwnerUserId,
      );
    } catch (_) {
      debugPrint(
        '[StoreService] Respuesta workspace stores no es JSON valido.',
      );
      return const <StoreModel>[];
    }
  }

  static List<StoreModel> _decodedWorkspaceStores(
    dynamic decoded, {
    String? restrictToOwnerUserId,
  }) {
    final ownerFilter = restrictToOwnerUserId?.trim();
    final filterByOwner =
        ownerFilter != null && ownerFilter.isNotEmpty ? ownerFilter : null;

    final out = <StoreModel>[];
    void addMap(Map<String, dynamic> map) {
      if (filterByOwner != null) {
        final rawOid = map['ownerUserId'];
        final oid = rawOid == null ? '' : rawOid.toString().trim();
        if (oid != filterByOwner) return;
      }
      final m = StoreModel.fromWorkspaceApi(map);
      if (m.id.isNotEmpty) out.add(m);
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final nested = map['stores'];
      if (nested is Map) {
        for (final dynamic v in nested.values) {
          if (v is Map) {
            addMap(Map<String, dynamic>.from(v));
          }
        }
        return List<StoreModel>.unmodifiable(out);
      }
      if (nested is List) {
        for (final dynamic v in nested) {
          if (v is Map) addMap(Map<String, dynamic>.from(v));
        }
        return List<StoreModel>.unmodifiable(out);
      }
      final idStr = map['id'] as String?;
      if ((idStr != null && idStr.trim().isNotEmpty) && map.containsKey('name')) {
        addMap(map);
        return List<StoreModel>.unmodifiable(out);
      }
    }
    if (decoded is List) {
      for (final dynamic v in decoded) {
        if (v is Map) {
          addMap(Map<String, dynamic>.from(v));
        }
      }
      return List<StoreModel>.unmodifiable(out);
    }
    return const <StoreModel>[];
  }

  static List<StoreModel> get stores => storesNotifier.value;

  static StoreModel? getById(String id) {
    for (final store in storesNotifier.value) {
      if (store.id == id) return store;
    }
    return null;
  }

  static String generateNewStoreId() => _generateId();

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
    final list =
        storesNotifier.value
            .where((store) => store.id != id)
            .toList(growable: false);
    storesNotifier.value = list;
    await _persist();
    await ProductService.deleteAllForStore(id);
    await ServiceService.deleteAllForStore(id);
  }

  static Future<void> clearAll() async {
    storesNotifier.value = const <StoreModel>[];
    storesLoadErrorNotifier.value = null;
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

  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(0xFFFF);
    return '$timestamp-${random.toRadixString(16)}';
  }
}
