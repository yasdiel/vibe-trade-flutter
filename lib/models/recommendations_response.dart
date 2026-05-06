import 'dart:convert';

import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';

/// Respuesta batch del feed de recomendaciones (tipo servidor `RecommendationBatchResponse`).
///
/// **Endpoints**: `GET …/Bootstrap` · `GET …/bootstrap/guest?guestId=` (carga inicial recomendada en el demo React) ·
/// `GET {api}/Recommendations?take=` · `GET …/Recommendations/guest?guestId=&take=` (refresco / lotes adicionales).
///
/// **Origen servidor (solo lectura, sin cursores)**  
/// - Lista ordenada [`offerIds`]: ranking después de aplicar filtros del viewer sobre candidatos públicos/publicados (`LoadOfferCandidatesAsync`), incl. IDs `emo_*` emergentes.
/// - [`offers`]: map id → `HomeOfferViewDto`; se rellena con `BuildOffersViewInOrderAsync` y luego `EnrichHomeOffersAsync` (`publicCommentCount` = tamaño QA, likes agregados, `viewerLikedOffer` por `likerKey` tipo `u:…` o `g:…`).
/// - [`storeBadges`]: `storeId` → mismo shape que ficha workspace (`StoreProfileWorkspaceData`) sólo tiendas tocadas por el batch.
///
/// Umbral ES del servidor llega como [`threshold`]; cuando `take` no se envía el backend usa tamaño omisión corto (~20): el cliente manda [`take`] explícito (~140 bootstrap).
class RecommendationsResponse {
  final List<String> offerIds;
  final Map<String, OfferModel> offers;
  final Map<String, StoreBadgeModel> storeBadges;
  final int batchSize;
  final double threshold;

  RecommendationsResponse({
    required this.offerIds,
    required this.offers,
    required this.storeBadges,
    required this.batchSize,
    required this.threshold,
  });

  /// Orden = [`offerIds`]. Si falta entrada en [`offers`], se omite (p.ej. error de parseo).
  List<OfferModel> get orderedOffers {
    final result = <OfferModel>[];
    for (final id in offerIds) {
      final offer = offers[id];
      if (offer != null) result.add(offer);
    }
    return result;
  }

  StoreBadgeModel? storeFor(OfferModel offer) => storeBadges[offer.storeId];

  /// Tiendas sidebar / FAB según primera aparición en el ranking de ofertas.
  List<String> storeIdsForHomeShelf() {
    final out = <String>[];
    final seen = <String>{};
    for (final oid in offerIds) {
      final o = offers[oid];
      if (o == null) continue;
      final sid = o.storeId.trim();
      if (sid.isEmpty || !seen.add(sid)) continue;
      if (storeBadges.containsKey(sid)) out.add(sid);
    }
    return out;
  }

  bool get hasStoreShelfTiles =>
      storeIdsForHomeShelf().isNotEmpty;

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    final rawOfferIds = _firstValue(normalized, const ['offerIds', 'OfferIds']);
    final rawOffers = _firstValue(normalized, const ['offers', 'Offers']);
    final rawStoreBadges = _firstValue(normalized, const [
      'storeBadges',
      'StoreBadges',
    ]);

    var offerIds = _parseOfferIds(rawOfferIds);
    final offers = _parseOffersMap(rawOffers);
    final storeBadges = _parseStoreBadgesMap(rawStoreBadges);

    /// Paridad con `normalizeRecommendationBatch` en React: si falta array de ids
    /// pero el mapa trae datos, conservar todas las tarjetas.
    if (offerIds.isEmpty && offers.isNotEmpty) {
      offerIds = offers.keys.toList(growable: false);
    }

    return RecommendationsResponse(
      offerIds: offerIds,
      offers: offers,
      storeBadges: storeBadges,
      batchSize: _readInt(normalized, const ['batchSize', 'BatchSize']) ?? 0,
      threshold: _readDouble(normalized, const ['threshold', 'Threshold']) ??
          0.0,
    );
  }
}

dynamic _unwrapJson(dynamic v) {
  if (v is String) {
    final t = v.trim();
    if (t.startsWith('{') && t.endsWith('}')) {
      try {
        return jsonDecode(t);
      } catch (_) {}
    }
  }
  return v;
}

dynamic _firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final k in keys) {
    if (map.containsKey(k)) return map[k];
  }
  return null;
}

int? _readInt(Map<String, dynamic> map, List<String> keys) {
  final v = _firstValue(map, keys);
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '');
}

double? _readDouble(Map<String, dynamic> map, List<String> keys) {
  final v = _firstValue(map, keys);
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '');
}

List<String> _parseOfferIds(dynamic raw) {
  final u = _unwrapJson(raw);
  if (u == null) return const [];
  if (u is! List) return const [];
  return u
      .map((e) => e?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}

/// Mapas `offers` / `Offers` (`HomeOfferViewDto`): bootstrap y batch de recomendaciones.
Map<String, OfferModel> parseHomeOffersMap(dynamic raw) =>
    _parseOffersMap(raw);

/// `stores` / `Stores` en `market` del bootstrap (`StoreProfileWorkspaceData`).
Map<String, StoreBadgeModel> parseHomeStoreBadgesMap(dynamic raw) =>
    _parseStoreBadgesMap(raw);

Map<String, OfferModel> _parseOffersMap(dynamic raw) {
  final out = <String, OfferModel>{};
  final u = _unwrapJson(raw);
  if (u is! Map) return out;

  Map<String, dynamic> coerceMap(dynamic m) =>
      Map<String, dynamic>.from(m as Map);

  final map = coerceMap(u);
  for (final e in map.entries) {
    final id = e.key.toString().trim();
    if (id.isEmpty) continue;
    final node = _unwrapJson(e.value);
    if (node is! Map) continue;
    try {
      out[id] = OfferModel.fromJson(coerceMap(node));
    } catch (_) {
      //
    }
  }
  return out;
}

Map<String, StoreBadgeModel> _parseStoreBadgesMap(dynamic raw) {
  final out = <String, StoreBadgeModel>{};
  final u = _unwrapJson(raw);
  if (u is! Map) return out;

  final map = Map<String, dynamic>.from(u as Map);
  for (final e in map.entries) {
    final id = e.key.toString().trim();
    if (id.isEmpty) continue;
    final node = _unwrapJson(e.value);
    if (node is! Map) continue;
    try {
      out[id] = StoreBadgeModel.fromJson(
        Map<String, dynamic>.from(node),
      );
    } catch (_) {
      //
    }
  }
  return out;
}
