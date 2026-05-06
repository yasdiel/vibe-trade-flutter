import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';

/// Producto en el bloque `catalog.products[]` del detalle de tienda.
///
/// Espejo de `StoreProductCatalogRowView` del backend
/// (`Features/Market/StoreCatalogRowViewDtos.cs`).
class StoreProductCatalogRowModel {
  final String id;
  final String storeId;
  final String? category;
  final String? name;
  final String? shortDescription;
  final String? mainBenefit;
  final String? technicalSpecs;
  final String? model;
  final String? condition;
  final String? price;
  final String? monedaPrecio;
  final List<String> monedas;
  final String? availability;
  final String? warrantyReturn;
  final String? contentIncluded;
  final String? usageConditions;
  final String? taxesShippingInstall;
  final bool transportIncluded;
  final bool published;
  final List<String> photoUrls;
  final int publicCommentCount;
  final int offerLikeCount;
  final bool viewerLikedOffer;

  const StoreProductCatalogRowModel({
    required this.id,
    required this.storeId,
    required this.category,
    required this.name,
    required this.shortDescription,
    required this.mainBenefit,
    required this.technicalSpecs,
    required this.model,
    required this.condition,
    required this.price,
    required this.monedaPrecio,
    required this.monedas,
    required this.availability,
    required this.warrantyReturn,
    required this.contentIncluded,
    required this.usageConditions,
    required this.taxesShippingInstall,
    required this.transportIncluded,
    required this.published,
    required this.photoUrls,
    required this.publicCommentCount,
    required this.offerLikeCount,
    required this.viewerLikedOffer,
  });

  factory StoreProductCatalogRowModel.fromJson(Map<String, dynamic> json) {
    return StoreProductCatalogRowModel(
      id: _str(json, ['id', 'Id']),
      storeId: _str(json, ['storeId', 'StoreId']),
      category: _strOrNull(json, ['category', 'Category']),
      name: _strOrNull(json, ['name', 'Name']),
      shortDescription:
          _strOrNull(json, ['shortDescription', 'ShortDescription']),
      mainBenefit: _strOrNull(json, ['mainBenefit', 'MainBenefit']),
      technicalSpecs: _strOrNull(json, ['technicalSpecs', 'TechnicalSpecs']),
      model: _strOrNull(json, ['model', 'Model']),
      condition: _strOrNull(json, ['condition', 'Condition']),
      price: _strOrNull(json, ['price', 'Price']),
      monedaPrecio: _strOrNull(json, ['monedaPrecio', 'MonedaPrecio']),
      monedas: _strList(json, ['monedas', 'Monedas']),
      availability: _strOrNull(json, ['availability', 'Availability']),
      warrantyReturn: _strOrNull(json, ['warrantyReturn', 'WarrantyReturn']),
      contentIncluded: _strOrNull(json, ['contentIncluded', 'ContentIncluded']),
      usageConditions: _strOrNull(json, ['usageConditions', 'UsageConditions']),
      taxesShippingInstall:
          _strOrNull(json, ['taxesShippingInstall', 'TaxesShippingInstall']),
      transportIncluded: _bool(json, ['transportIncluded', 'TransportIncluded']),
      published: _bool(json, ['published', 'Published']),
      photoUrls: _strList(json, ['photoUrls', 'PhotoUrls']),
      publicCommentCount: _int(json, ['publicCommentCount', 'PublicCommentCount']) ?? 0,
      offerLikeCount: _int(json, ['offerLikeCount', 'OfferLikeCount']) ?? 0,
      viewerLikedOffer: _bool(json, ['viewerLikedOffer', 'ViewerLikedOffer']),
    );
  }

  /// Texto principal (nombre o categoria como fallback).
  String get displayTitle {
    final n = (name ?? '').trim();
    if (n.isNotEmpty) return n;
    final c = (category ?? '').trim();
    return c.isEmpty ? 'Producto' : c;
  }

  /// "12 USD" si hay precio + moneda; si no, lo mejor disponible.
  String get displayPrice {
    final p = (price ?? '').trim();
    final c = (monedaPrecio ?? '').trim();
    if (p.isEmpty && c.isEmpty) return '-';
    if (p.isEmpty) return c;
    if (c.isEmpty) return p;
    return '$p $c';
  }
}

/// Servicio en el bloque `catalog.services[]` del detalle de tienda.
///
/// Espejo de `StoreServiceCatalogRowView` del backend.
class StoreServiceCatalogRowModel {
  final String id;
  final String storeId;
  final String? category;
  final String? tipoServicio;
  final String? descripcion;
  final String? incluye;
  final String? noIncluye;
  final String? entregables;
  final String? propIntelectual;
  final bool published;
  final List<String> monedas;
  final List<String> photoUrls;
  final int publicCommentCount;
  final int offerLikeCount;
  final bool viewerLikedOffer;

  const StoreServiceCatalogRowModel({
    required this.id,
    required this.storeId,
    required this.category,
    required this.tipoServicio,
    required this.descripcion,
    required this.incluye,
    required this.noIncluye,
    required this.entregables,
    required this.propIntelectual,
    required this.published,
    required this.monedas,
    required this.photoUrls,
    required this.publicCommentCount,
    required this.offerLikeCount,
    required this.viewerLikedOffer,
  });

  factory StoreServiceCatalogRowModel.fromJson(Map<String, dynamic> json) {
    return StoreServiceCatalogRowModel(
      id: _str(json, ['id', 'Id']),
      storeId: _str(json, ['storeId', 'StoreId']),
      category: _strOrNull(json, ['category', 'Category']),
      tipoServicio: _strOrNull(json, ['tipoServicio', 'TipoServicio']),
      descripcion: _strOrNull(json, ['descripcion', 'Descripcion']),
      incluye: _strOrNull(json, ['incluye', 'Incluye']),
      noIncluye: _strOrNull(json, ['noIncluye', 'NoIncluye']),
      entregables: _strOrNull(json, ['entregables', 'Entregables']),
      propIntelectual: _strOrNull(json, ['propIntelectual', 'PropIntelectual']),
      published: _bool(json, ['published', 'Published']),
      monedas: _strList(json, ['monedas', 'Monedas']),
      photoUrls: _strList(json, ['photoUrls', 'PhotoUrls']),
      publicCommentCount: _int(json, ['publicCommentCount', 'PublicCommentCount']) ?? 0,
      offerLikeCount: _int(json, ['offerLikeCount', 'OfferLikeCount']) ?? 0,
      viewerLikedOffer: _bool(json, ['viewerLikedOffer', 'ViewerLikedOffer']),
    );
  }

  String get displayTitle {
    final t = (tipoServicio ?? '').trim();
    if (t.isNotEmpty) return t;
    final c = (category ?? '').trim();
    return c.isEmpty ? 'Servicio' : c;
  }
}

/// Bloque `catalog` dentro de la respuesta de detalle de tienda.
class StoreCatalogBlockModel {
  final String pitch;
  final List<StoreProductCatalogRowModel> products;
  final List<StoreServiceCatalogRowModel> services;
  /// Publicaciones emergentes (`emo_*`) del catalogo de la tienda. Se hidratan
  /// si la respuesta las trae bajo `emergentPublications` o `emergents`.
  final List<OfferModel> emergents;

  const StoreCatalogBlockModel({
    required this.pitch,
    required this.products,
    required this.services,
    required this.emergents,
  });

  factory StoreCatalogBlockModel.fromJson(Map<String, dynamic> json) {
    final products = <StoreProductCatalogRowModel>[];
    final rawProducts = json['products'] ?? json['Products'];
    if (rawProducts is List) {
      for (final raw in rawProducts) {
        if (raw is Map) {
          products.add(StoreProductCatalogRowModel.fromJson(
            Map<String, dynamic>.from(raw),
          ));
        }
      }
    }

    final services = <StoreServiceCatalogRowModel>[];
    final rawServices = json['services'] ?? json['Services'];
    if (rawServices is List) {
      for (final raw in rawServices) {
        if (raw is Map) {
          services.add(StoreServiceCatalogRowModel.fromJson(
            Map<String, dynamic>.from(raw),
          ));
        }
      }
    }

    final emergents = <OfferModel>[];
    final rawEmergents = json['emergentPublications'] ??
        json['EmergentPublications'] ??
        json['emergents'] ??
        json['Emergents'];
    if (rawEmergents is List) {
      for (final raw in rawEmergents) {
        if (raw is Map) {
          emergents.add(OfferModel.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    return StoreCatalogBlockModel(
      pitch: _str(json, ['pitch', 'Pitch']),
      products: products,
      services: services,
      emergents: emergents,
    );
  }
}

/// Datos del dueno expuestos en la respuesta de detalle.
class StoreDetailOwnerModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final int trustScore;

  const StoreDetailOwnerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.trustScore,
  });

  factory StoreDetailOwnerModel.fromJson(Map<String, dynamic> json) {
    return StoreDetailOwnerModel(
      id: _str(json, ['id', 'Id']),
      name: _str(json, ['name', 'Name']),
      avatarUrl: _strOrNull(json, ['avatarUrl', 'AvatarUrl']),
      trustScore: _int(json, ['trustScore', 'TrustScore']) ?? 0,
    );
  }
}

/// Respuesta unificada de `POST /Market/stores/{id}/detail`.
class StoreDetailResponse {
  final StoreBadgeModel store;
  final StoreCatalogBlockModel catalog;
  final StoreDetailOwnerModel? owner;

  const StoreDetailResponse({
    required this.store,
    required this.catalog,
    required this.owner,
  });

  factory StoreDetailResponse.fromJson(Map<String, dynamic> json) {
    final storeRaw = json['store'] ?? json['Store'];
    if (storeRaw is! Map) {
      throw const FormatException('Detalle de tienda sin nodo "store".');
    }
    final catalogRaw = json['catalog'] ?? json['Catalog'];
    final catalog = catalogRaw is Map
        ? StoreCatalogBlockModel.fromJson(Map<String, dynamic>.from(catalogRaw))
        : const StoreCatalogBlockModel(
            pitch: '',
            products: [],
            services: [],
            emergents: [],
          );
    final ownerRaw = json['owner'] ?? json['Owner'];
    final owner = ownerRaw is Map
        ? StoreDetailOwnerModel.fromJson(Map<String, dynamic>.from(ownerRaw))
        : null;
    return StoreDetailResponse(
      store: StoreBadgeModel.fromJson(Map<String, dynamic>.from(storeRaw)),
      catalog: catalog,
      owner: owner,
    );
  }
}

/// Respuesta de `GET /Market/offers/{id}/card`.
class PublicOfferCardResponse {
  final OfferModel offer;
  final StoreBadgeModel store;

  const PublicOfferCardResponse({required this.offer, required this.store});

  factory PublicOfferCardResponse.fromJson(Map<String, dynamic> json) {
    final offerRaw = json['offer'] ?? json['Offer'];
    final storeRaw = json['store'] ?? json['Store'];
    if (offerRaw is! Map || storeRaw is! Map) {
      throw const FormatException('Respuesta de oferta sin "offer" o "store".');
    }
    return PublicOfferCardResponse(
      offer: OfferModel.fromJson(Map<String, dynamic>.from(offerRaw)),
      store: StoreBadgeModel.fromJson(Map<String, dynamic>.from(storeRaw)),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers (lectura tolerante: claves en camelCase y PascalCase coexisten en
// distintos niveles del JSON .NET).
// ---------------------------------------------------------------------------

String _str(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is String) return v.trim();
    if (v != null) return v.toString().trim();
  }
  return '';
}

String? _strOrNull(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    if (v != null && v is! Map && v is! List) {
      final t = v.toString().trim();
      return t.isEmpty ? null : t;
    }
  }
  return null;
}

bool _bool(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
  }
  return false;
}

int? _int(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v.trim());
      if (p != null) return p;
    }
  }
  return null;
}

List<String> _strList(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is List) {
      return v
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
    }
  }
  return const [];
}
