import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';

/// Cliente del catalogo (publico, no requiere sesion):
/// - `GET /api/v1/Market/stores/search` busqueda con filtros y paginacion.
/// - `GET /api/v1/Market/stores/autocomplete` sugerencias rapidas para el input.
///
/// Modelos espejo del demo en React (`searchStores.ts`).
class CatalogSearchService {
  static String get _searchUrl => '$baseUrl/Market/stores/search';
  static String get _autocompleteUrl =>
      '$baseUrl/Market/stores/autocomplete';

  /// Busqueda paginada (mezcla tiendas + ofertas + servicios + emergentes).
  static Future<CatalogSearchPage> search({
    String? name,
    List<String>? categories,
    List<CatalogSearchKind>? kinds,
    double? trustMin,
    double? lat,
    double? lng,
    double? km,
    int limit = 20,
    int offset = 0,
  }) async {
    final qs = <String, String>{};
    final cleanName = name?.trim() ?? '';
    if (cleanName.isNotEmpty) qs['name'] = cleanName;

    final cleanCategories =
        (categories ?? const <String>[]).where((c) => c.trim().isNotEmpty);
    if (cleanCategories.isNotEmpty) {
      qs['category'] = cleanCategories.join(',');
    }

    final cleanKinds = (kinds ?? CatalogSearchKind.values);
    if (cleanKinds.isNotEmpty) {
      qs['kinds'] = cleanKinds.map((k) => k.wireName).join(',');
    }

    if (trustMin != null && trustMin.isFinite) {
      qs['trustMin'] = trustMin.toInt().toString();
    }
    if (lat != null && lat.isFinite) qs['lat'] = lat.toString();
    if (lng != null && lng.isFinite) qs['lng'] = lng.toString();
    if (km != null && km.isFinite && km > 0) qs['km'] = km.toString();
    qs['limit'] = limit.toString();
    if (offset > 0) qs['offset'] = offset.toString();

    final uri = Uri.parse(_searchUrl).replace(queryParameters: qs);
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo buscar en el catalogo (${response.statusCode}).',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return const CatalogSearchPage(items: [], hasMore: false);
    }
    final rawItems = decoded['items'];
    final items = <CatalogSearchItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          final parsed =
              CatalogSearchItem.tryParse(Map<String, dynamic>.from(raw));
          if (parsed != null) items.add(parsed);
        }
      }
    }
    final hasMore = decoded['hasMore'] == true;
    return CatalogSearchPage(items: items, hasMore: hasMore);
  }

  /// Sugerencias para el input de texto. Devuelve lista plana de strings.
  static Future<List<String>> autocomplete(
    String query, {
    List<CatalogSearchKind>? kinds,
    List<String>? categories,
    int limit = 10,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    final qs = <String, String>{
      'q': q,
      'limit': limit.toString(),
    };
    if (kinds != null && kinds.isNotEmpty) {
      qs['kinds'] = kinds.map((k) => k.wireName).join(',');
    }
    if (categories != null && categories.isNotEmpty) {
      qs['category'] = categories.where((c) => c.trim().isNotEmpty).join(',');
    }

    final uri = Uri.parse(_autocompleteUrl).replace(queryParameters: qs);
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    final raw = decoded['suggestions'];
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
}

enum CatalogSearchKind { store, product, service, emergent }

extension CatalogSearchKindX on CatalogSearchKind {
  String get wireName {
    switch (this) {
      case CatalogSearchKind.store:
        return 'store';
      case CatalogSearchKind.product:
        return 'product';
      case CatalogSearchKind.service:
        return 'service';
      case CatalogSearchKind.emergent:
        return 'emergent';
    }
  }

  String get label {
    switch (this) {
      case CatalogSearchKind.store:
        return 'Tiendas';
      case CatalogSearchKind.product:
        return 'Productos';
      case CatalogSearchKind.service:
        return 'Servicios';
      case CatalogSearchKind.emergent:
        return 'Hojas de ruta';
    }
  }

  static CatalogSearchKind? tryFromWire(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'store':
        return CatalogSearchKind.store;
      case 'product':
        return CatalogSearchKind.product;
      case 'service':
        return CatalogSearchKind.service;
      case 'emergent':
        return CatalogSearchKind.emergent;
    }
    return null;
  }
}

/// Snapshot de oferta resumida para tarjetas de busqueda. No usamos `OfferModel`
/// porque el shape del backend (`MarketCatalogStoreSearchService`) trae menos
/// campos y, en el caso de las hojas de ruta, normaliza los strings antes de
/// emitir el JSON.
class CatalogSearchOffer {
  final String id;
  final CatalogSearchKind kind;
  final String name;
  final String category;
  final String price;
  final String currency;
  final List<String> acceptedCurrencies;
  final List<String> photoUrls;
  final String tipoServicio;
  final String shortDescription;

  const CatalogSearchOffer({
    required this.id,
    required this.kind,
    required this.name,
    required this.category,
    required this.price,
    required this.currency,
    required this.acceptedCurrencies,
    required this.photoUrls,
    required this.tipoServicio,
    required this.shortDescription,
  });

  static CatalogSearchOffer? tryParse(
    Map<String, dynamic> json, {
    required CatalogSearchKind itemKind,
  }) {
    final id = ((json['id'] ?? json['Id']) as Object?)?.toString().trim() ?? '';
    if (id.isEmpty) return null;

    final isEmergent = itemKind == CatalogSearchKind.emergent ||
        json['isEmergentRoutePublication'] == true ||
        json['IsEmergentRoutePublication'] == true ||
        id.startsWith('emo_');

    final name = ((json['name'] ?? json['title'] ?? json['Title']) as Object?)
            ?.toString()
            .trim() ??
        '';
    final category =
        ((json['category'] ?? json['Category']) as Object?)?.toString().trim() ??
            '';
    final price = ((json['price'] ?? json['Price']) as Object?)?.toString().trim() ??
        '';
    final currency =
        ((json['currency'] ?? json['Currency']) as Object?)?.toString().trim() ??
            '';

    final rawAcc =
        (json['acceptedCurrencies'] ?? json['AcceptedCurrencies']) as List?;
    final accepted = (rawAcc ?? const <dynamic>[])
        .whereType<String>()
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList(growable: false);

    final rawPhotos = (json['photoUrls'] ?? json['PhotoUrls']) as List?;
    final photos = <String>[];
    if (rawPhotos != null) {
      for (final raw in rawPhotos) {
        if (raw is String && raw.trim().isNotEmpty) photos.add(raw.trim());
      }
    }
    final rawImgs = (json['imageUrls'] ?? json['ImageUrls']) as List?;
    if (rawImgs != null) {
      for (final raw in rawImgs) {
        if (raw is String && raw.trim().isNotEmpty) photos.add(raw.trim());
      }
    }
    final singleImg =
        ((json['imageUrl'] ?? json['ImageUrl']) as Object?)?.toString().trim() ??
            '';
    if (singleImg.isNotEmpty) photos.add(singleImg);

    final tipoServicio =
        ((json['tipoServicio'] ?? json['TipoServicio']) as Object?)
                ?.toString()
                .trim() ??
            '';

    final shortDesc = ((json['shortDescription'] ??
                json['ShortDescription'] ??
                json['descripcion'] ??
                json['Descripcion'] ??
                json['description'] ??
                json['Description']) as Object?)
            ?.toString()
            .trim() ??
        '';

    final resolvedKind = isEmergent
        ? CatalogSearchKind.emergent
        : itemKind == CatalogSearchKind.store
            ? CatalogSearchKind.product
            : itemKind;

    return CatalogSearchOffer(
      id: id,
      kind: resolvedKind,
      name: name,
      category: category,
      price: price,
      currency: currency,
      acceptedCurrencies: accepted,
      photoUrls: photos.toSet().toList(growable: false),
      tipoServicio: tipoServicio,
      shortDescription: shortDesc,
    );
  }
}

class CatalogSearchItem {
  final CatalogSearchKind kind;
  final StoreBadgeModel store;
  final CatalogSearchOffer? offer;
  final int publishedProducts;
  final int publishedServices;
  final double? distanceKm;

  const CatalogSearchItem({
    required this.kind,
    required this.store,
    required this.offer,
    required this.publishedProducts,
    required this.publishedServices,
    required this.distanceKm,
  });

  static CatalogSearchItem? tryParse(Map<String, dynamic> json) {
    final kind = CatalogSearchKindX.tryFromWire(json['kind'] as String?);
    if (kind == null) return null;
    final storeRaw = json['store'];
    if (storeRaw is! Map) return null;
    final StoreBadgeModel store;
    try {
      store = StoreBadgeModel.fromJson(Map<String, dynamic>.from(storeRaw));
    } catch (_) {
      return null;
    }
    if (store.id.isEmpty) return null;

    CatalogSearchOffer? offer;
    final offerRaw = json['offer'] ?? json['Offer'];
    if (offerRaw is Map) {
      offer = CatalogSearchOffer.tryParse(
        Map<String, dynamic>.from(offerRaw),
        itemKind: kind,
      );
    } else if (offerRaw is String && offerRaw.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(offerRaw);
        if (decoded is Map) {
          offer = CatalogSearchOffer.tryParse(
            Map<String, dynamic>.from(decoded),
            itemKind: kind,
          );
        }
      } catch (_) {
        offer = null;
      }
    }

    int parseInt(dynamic raw) {
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw.trim()) ?? 0;
      return 0;
    }

    double? parseDouble(dynamic raw) {
      if (raw is num) {
        final d = raw.toDouble();
        return d.isFinite ? d : null;
      }
      if (raw is String) {
        final p = double.tryParse(raw.trim());
        return p != null && p.isFinite ? p : null;
      }
      return null;
    }

    return CatalogSearchItem(
      kind: kind,
      store: store,
      offer: offer,
      publishedProducts: parseInt(json['publishedProducts']),
      publishedServices: parseInt(json['publishedServices']),
      distanceKm: parseDouble(json['distanceKm']),
    );
  }
}

class CatalogSearchPage {
  final List<CatalogSearchItem> items;
  final bool hasMore;

  const CatalogSearchPage({required this.items, required this.hasMore});
}
