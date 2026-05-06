import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/catalog_detail_model.dart';
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

/// Rutas útiles (`baseUrl` = `…/api/v1`):
///
/// **Perfil de tienda (listar tus tiendas filtradas en cliente / crear / editar)**  
/// - [`GET /Market/workspace/stores`](fetchWorkspaceStores) — JSON `{ "stores": { "<id>": {...} } }`. Requiere `Authorization: Bearer`.  
/// - [`PUT /Market/workspace/stores`](upsertWorkspaceStoreProfile) — mismo path; body **plano** con `id` (y `ownerUserId`, nombre, categorías, etc.). Alta y edición usan esta misma ruta (upsert por `id`).
///
/// **Otras rutas "stores" (no usar para alta/edición/listado workspace)**  
/// - `GET /Market/stores/search`, `GET /Market/stores/autocomplete` — búsqueda pública del catálogo.  
/// - `PUT /Market/stores/{storeId}/products/...`, `.../services/...` — productos/servicios, no el perfil de la tienda.  
/// - `GET /Market/workspace` — snapshot completo del mercado (no es el endpoint ligero de solo tiendas).
class MarketService {
  static String get _catalogCategoriesUrl =>
      '$baseUrl/Market/catalog-categories';

  static String get _currenciesUrl => '$baseUrl/Market/currencies';

  static String get _workspaceStoresUrl => '$baseUrl/Market/workspace/stores';

  static String get _workspaceUrl => '$baseUrl/Market/workspace';

  /// GET catálogo de tiendas desde PostgreSQL (shape `{ "stores": { ... } }`).
  static Future<http.Response> fetchWorkspaceStores() async {
    final token = await SessionService.getSavedToken();
    if (token == null) {
      throw const UnauthorizedException();
    }

    final response = await http.get(
      Uri.parse(_workspaceStoresUrl),
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }

    return response;
  }

  /// Snapshot `{ "offers": { id: {...} }, "stores": { id: {...} } }`.
  static Future<WorkspaceMarketSnapshot> fetchWorkspaceMarketMaps() async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final response = await http.get(
      Uri.parse(_workspaceUrl),
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo cargar el mercado (${response.statusCode}).',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const WorkspaceMarketSnapshot(offers: {}, stores: {});
    }

    final offers = <String, OfferModel>{};
    final rawOffers = decoded['offers'];
    if (rawOffers is Map) {
      rawOffers.forEach((key, value) {
        if (key is String && value is Map) {
          offers[key] = OfferModel.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }

    final stores = <String, StoreBadgeModel>{};
    final rawStores = decoded['stores'];
    if (rawStores is Map) {
      rawStores.forEach((key, value) {
        if (key is String && value is Map) {
          stores[key] =
              StoreBadgeModel.fromJson(Map<String, dynamic>.from(value));
        }
      });
    }

    return WorkspaceMarketSnapshot(offers: offers, stores: stores);
  }

  /// `POST /Market/offers/{offerId}/like` — alterna me gusta (requiere sesion).
  static Future<({bool liked, int likeCount})> toggleOfferLike(
    String offerId,
  ) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final oid = offerId.trim();
    final uri = Uri.parse(
      '$baseUrl/Market/offers/${Uri.encodeComponent(oid)}/like',
    );
    final response = await http.post(
      uri,
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: '{}',
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo actualizar el me gusta.',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return (liked: false, likeCount: 0);
    }
    final liked = decoded['liked'] as bool? ?? false;
    final likeCount =
        (decoded['likeCount'] as num?)?.toInt() ?? 0;
    return (liked: liked, likeCount: likeCount);
  }

  /// PUT `{baseUrl}/Market/workspace/stores` — firma recomendada: JSON plano con
  /// `"id"` (normalizador del backend).
  static Future<void> upsertWorkspaceStoreProfile({
    required String storeId,
    required String ownerUserId,
    required String name,
    required String pitch,
    required List<String> categories,
    required bool transportIncluded,
    required bool verified,
    required int trustScore,
    String? websiteUrl,
    String? avatarUrl,
    double? latitude,
    double? longitude,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final body = <String, dynamic>{
      'id': storeId,
      'ownerUserId': ownerUserId,
      'name': name.trim(),
      'verified': verified,
      'categories': categories,
      'transportIncluded': transportIncluded,
      'trustScore': trustScore.clamp(0, 100),
      'pitch': pitch.trim(),
      'websiteUrl': (websiteUrl ?? '').trim(),
    };

    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      body['avatarUrl'] = avatarUrl.trim();
    } else {
      body['avatarUrl'] = null;
    }

    if (latitude != null && longitude != null) {
      body['location'] = {
        'lat': latitude,
        'lng': longitude,
      };
    }

    final response = await http.put(
      Uri.parse(_workspaceStoresUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode >= 400) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: _fallbackPutStoreMessage(response.statusCode),
        ),
      );
    }
  }

  static String _fallbackPutStoreMessage(int code) =>
      code == 409
          ? 'Ya existe una tienda con ese nombre en la plataforma.'
          : 'No se pudo guardar la tienda (HTTP $code).';

  static Future<List<String>> getCatalogCategories() async {
    final response = await http.get(Uri.parse(_catalogCategoriesUrl));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudieron cargar las categorias: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> rawList = decoded is Map<String, dynamic>
        ? (decoded['categories'] as List<dynamic>? ?? const <dynamic>[])
        : (decoded is List<dynamic> ? decoded : const <dynamic>[]);

    return rawList
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  /// `POST …/stores/{storeId}/detail` — incluye `catalog.products` y `catalog.services`.
  static Future<Map<String, dynamic>> fetchStoreCatalogDetailDecoded(
    String storeId,
  ) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final sid = storeId.trim();
    final uri = Uri.parse(
      '$baseUrl/Market/stores/${Uri.encodeComponent(sid)}/detail',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
      body: '{}',
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode == 404) {
      throw Exception('No existe esa tienda.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo cargar el catalogo (${response.statusCode}).',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return const <String, dynamic>{};
  }

  static Future<void> putStoreProduct({
    required String storeId,
    required String productId,
    required Map<String, dynamic> body,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final uri = Uri.parse(
      '$baseUrl/Market/stores/${Uri.encodeComponent(storeId.trim())}/products/${Uri.encodeComponent(productId.trim())}',
    );
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: _catalogUpsertFallback(response.statusCode),
        ),
      );
    }
  }

  static Future<void> deleteStoreProduct({
    required String storeId,
    required String productId,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final uri = Uri.parse(
      '$baseUrl/Market/stores/${Uri.encodeComponent(storeId.trim())}/products/${Uri.encodeComponent(productId.trim())}',
    );
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: _catalogUpsertFallback(response.statusCode),
        ),
      );
    }
  }

  static Future<void> putStoreService({
    required String storeId,
    required String serviceId,
    required Map<String, dynamic> body,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final uri = Uri.parse(
      '$baseUrl/Market/stores/${Uri.encodeComponent(storeId.trim())}/services/${Uri.encodeComponent(serviceId.trim())}',
    );
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: _catalogUpsertFallback(response.statusCode),
        ),
      );
    }
  }

  static Future<void> deleteStoreService({
    required String storeId,
    required String serviceId,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final uri = Uri.parse(
      '$baseUrl/Market/stores/${Uri.encodeComponent(storeId.trim())}/services/${Uri.encodeComponent(serviceId.trim())}',
    );
    final response = await http.delete(
      uri,
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: _catalogUpsertFallback(response.statusCode),
        ),
      );
    }
  }

  static String _catalogUpsertFallback(int code) {
    if (code == 403) return 'No tenes permiso para modificar este catalogo.';
    if (code == 404) return 'No encontramos esa tienda o ese articulo.';
    return 'Error del servidor en catalogo (HTTP $code).';
  }

  /// `POST /Market/stores/{storeId}/detail` — publico (anonimo o con sesion).
  ///
  /// El demo en React lo usa para abrir la "vitrina" de cualquier tienda.
  /// Si hay token persistido se adjunta `Authorization` y el backend enriquece
  /// el bloque con `viewerLikedOffer` y demas datos personalizados.
  static Future<StoreDetailResponse> fetchPublicStoreDetail(
    String storeId,
  ) async {
    final sid = storeId.trim();
    final uri = Uri.parse(
      '$baseUrl/Market/stores/${Uri.encodeComponent(sid)}/detail',
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await SessionService.getSavedToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = SessionService.buildAuthorizationHeader(token);
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(<String, dynamic>{
        'viewerUserId': null,
        'viewerRole': null,
      }),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      // Si la sesion expiro la limpiamos pero seguimos pudiendo mostrar la
      // tienda en modo invitado: rehacemos la llamada anonima.
      await SessionService.handleUnauthorized();
      final retry = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: '{}',
      );
      if (retry.statusCode == 404) {
        throw Exception('No existe esa tienda.');
      }
      if (retry.statusCode < 200 || retry.statusCode >= 300) {
        throw Exception(
          ApiResponseUtils.extractErrorMessage(
            retry,
            fallback: 'No se pudo cargar la tienda (${retry.statusCode}).',
          ),
        );
      }
      return _decodeStoreDetail(retry.body);
    }
    if (response.statusCode == 404) {
      throw Exception('No existe esa tienda.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo cargar la tienda (${response.statusCode}).',
        ),
      );
    }
    return _decodeStoreDetail(response.body);
  }

  static StoreDetailResponse _decodeStoreDetail(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de tienda no es JSON objeto.');
    }
    return StoreDetailResponse.fromJson(decoded);
  }

  /// `GET /Market/offers/{offerId}/card` — publico.
  ///
  /// Devuelve la oferta + su tienda. Mismo endpoint que el demo en React:
  /// `fetchPublicOfferCard` en `src/utils/market/marketPersistence.ts`.
  static Future<PublicOfferCardResponse> fetchPublicOfferCard(
    String offerId,
  ) async {
    final oid = offerId.trim();
    if (oid.isEmpty) throw Exception('Id de oferta vacio.');

    final uri = Uri.parse(
      '$baseUrl/Market/offers/${Uri.encodeComponent(oid)}/card',
    );
    final headers = <String, String>{'Accept': 'application/json'};
    final token = await SessionService.getSavedToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = SessionService.buildAuthorizationHeader(token);
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 404) {
      throw Exception('No existe esa oferta.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo cargar la oferta (${response.statusCode}).',
        ),
      );
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de oferta no es JSON objeto.');
    }
    return PublicOfferCardResponse.fromJson(decoded);
  }

  static Future<List<ProductCurrency>> getCurrencies() async {
    final response = await http.get(Uri.parse(_currenciesUrl));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudieron cargar las monedas: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> rawList = decoded is Map<String, dynamic>
        ? (decoded['currencies'] as List<dynamic>? ?? const <dynamic>[])
        : (decoded is List<dynamic> ? decoded : const <dynamic>[]);

    final seen = <ProductCurrency>{};
    final result = <ProductCurrency>[];
    for (final raw in rawList.whereType<String>()) {
      final currency = ProductCurrency.fromValue(raw.trim());
      if (currency != null && seen.add(currency)) {
        result.add(currency);
      }
    }
    return result;
  }
}

class WorkspaceMarketSnapshot {
  final Map<String, OfferModel> offers;
  final Map<String, StoreBadgeModel> stores;

  const WorkspaceMarketSnapshot({
    required this.offers,
    required this.stores,
  });
}
