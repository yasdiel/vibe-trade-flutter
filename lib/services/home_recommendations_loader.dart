import 'package:flutter/foundation.dart';
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/recommendations_response.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/bootstrap_root_service.dart';
import 'package:vibe_trade_v1/services/recommendations_service.dart';
import 'package:vibe_trade_v1/services/saved_offers_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

/// Igual que `RECOMMENDATION_API_TAKE` en `homeFeedMerge.ts` del demo React.
const int kHomeRecommendationBootstrapTake = 140;

/// Paridad demo React [`bootstrapWebApp`]: **`GET Bootstrap` / `GET bootstrap/guest`**
/// aporta el mercado inicial y el ranking en `recommendations`; después el home refina el feed
/// con **`GET Recommendations`**.
class HomeRecommendationsLoader {
  HomeRecommendationsLoader._();

  /// Opcionalmente sincroniza `savedOfferIds` del mismo JSON bootstrap (solo si hay sesión).
  static void applySavedOffersFromBootstrap(Map<String, dynamic> root) {
    if (!SessionService.isLoggedInNotifier.value) return;
    final dynamic raw =
        root['savedOfferIds'] ?? root['SavedOfferIds'];
    if (raw is! List) return;
    final ids = raw
        .map((e) => e?.toString().trim() ?? '')
        .where((String s) => s.isNotEmpty)
        .toSet();
    SavedOffersService.idsNotifier.value = ids;
  }

  /// Estructura paralela a `bootstrapWebApp` en `bootstrapWebApp.ts`.
  static RecommendationsResponse mergeBootstrapIntoHomeFeed(
    Map<String, dynamic> root,
  ) {
    final dynamic marketDyn = root['market'] ?? root['Market'];
    final marketMap = marketDyn is Map
        ? Map<String, dynamic>.from(marketDyn as Map)
        : <String, dynamic>{};

    final dynamic recDyn =
        root['recommendations'] ?? root['Recommendations'];
    final Map<String, dynamic> recMap = recDyn is Map
        ? Map<String, dynamic>.from(recDyn as Map)
        : <String, dynamic>{};
    final recParsed = RecommendationsResponse.fromJson(recMap);

    var fromRec = recParsed.offerIds.isNotEmpty
        ? List<String>.from(recParsed.offerIds)
        : recParsed.offers.keys.toList(growable: false);
    fromRec =
        _sliceTakeTrimmed(fromRec, kHomeRecommendationBootstrapTake);

    final dynamic rawMarketOfferIds =
        marketMap['offerIds'] ?? marketMap['OfferIds'];
    var fromMarket = <String>[];
    if (rawMarketOfferIds is List) {
      fromMarket = _sliceTakeTrimmed(
        rawMarketOfferIds
            .map((e) => e?.toString().trim() ?? '')
            .where((String s) => s.isNotEmpty)
            .toList(growable: false),
        kHomeRecommendationBootstrapTake,
      );
    }

    var bootOfferIds = fromRec.isNotEmpty ? fromRec : fromMarket;
    if (bootOfferIds.isEmpty) {
      final dynamic offersDyn = marketMap['offers'] ?? marketMap['Offers'];
      if (offersDyn is Map) {
        bootOfferIds = _sliceTakeTrimmed(
          offersDyn.keys
              .map((k) => k.toString().trim())
              .where((String s) => s.isNotEmpty)
              .toList(growable: false),
          kHomeRecommendationBootstrapTake,
        );
      }
    }

    final marketOffers = parseHomeOffersMap(
      marketMap['offers'] ?? marketMap['Offers'],
    );
    final marketStores = parseHomeStoreBadgesMap(
      marketMap['stores'] ?? marketMap['Stores'],
    );

    final mergedOffers = <String, OfferModel>{
      ...marketOffers,
      ...recParsed.offers,
    };
    final mergedStores = <String, StoreBadgeModel>{
      ...marketStores,
      ...recParsed.storeBadges,
    };

    final threshold =
        recParsed.threshold != 0.0 ? recParsed.threshold : 0.35;
    final batchSize = recParsed.batchSize > 0
        ? recParsed.batchSize
        : kHomeRecommendationBootstrapTake;

    return RecommendationsResponse(
      offerIds: bootOfferIds,
      offers: mergedOffers,
      storeBadges: mergedStores,
      batchSize: batchSize,
      threshold: threshold,
    );
  }

  /// Prefiere mapas [`offers`] / [`storeBadges`] del lote Recommendations pero rellena
  /// huecos desde el mismo JSON bootstrap (casos de ids en [`offerIds`] sin ficha parsada).
  static RecommendationsResponse _overlayBootstrapFallback(
    RecommendationsResponse api,
    RecommendationsResponse bootstrapBase,
  ) {
    if (api.offerIds.isEmpty) return api;
    return RecommendationsResponse(
      offerIds: api.offerIds,
      offers: {
        ...bootstrapBase.offers,
        ...api.offers,
      },
      storeBadges: {
        ...bootstrapBase.storeBadges,
        ...api.storeBadges,
      },
      batchSize: api.batchSize > 0 ? api.batchSize : bootstrapBase.batchSize,
      threshold: api.threshold != 0.0 ? api.threshold : bootstrapBase.threshold,
    );
  }

  /// 1) **`GET Bootstrap` / guest** → igual que el demo React al arrancar (merge mercado +
  /// recomendaciones del bootstrap). Opcionalmente [onBootstrapFeedReady] para pintar el home
  /// antes del paso 2.
  ///
  /// 2) **`GET Recommendations`** (ranking fresco). Si llega incompleto, se mezcla con los mapas
  /// del paso 1.
  ///
  /// 3) Si el ranking dedicado viene vacío o falla, se sirve sólo lo fusionado en 1).
  ///
  /// [logBootstrapResponseBody]: en modo debug imprime JSON del Bootstrap.
  /// [logRecommendationsResponseBody]: en modo debug imprime JSON de `GET Recommendations`.
  static Future<RecommendationsResponse> loadForHome({
    int take = RecommendationsService.defaultTake,
    bool logRecommendationsResponseBody = false,
    // Solo efecto en debug (kDebugMode): ver BootstrapRootService.fetchRootJson.
    bool logBootstrapResponseBody = false,
    void Function(RecommendationsResponse bootstrapMerged)?
        onBootstrapFeedReady,
  }) async {
    Map<String, dynamic>? root;
    try {
      root = await BootstrapRootService.fetchRootJson(
        logResponseBody: logBootstrapResponseBody,
      );
    } catch (_) {
      root = null;
    }

    RecommendationsResponse? bootstrapMerged;
    if (root != null) {
      applySavedOffersFromBootstrap(root);
      bootstrapMerged = mergeBootstrapIntoHomeFeed(root);
      if (bootstrapMerged.orderedOffers.isNotEmpty) {
        onBootstrapFeedReady?.call(bootstrapMerged);
      }
    }

    RecommendationsResponse? apiBag;
    try {
      apiBag = await RecommendationsService.fetchRecommendations(
        take: take,
        logResponseBody: logRecommendationsResponseBody,
      );
    } on UnauthorizedException {
      // Igual que el demo web: si el ranking dedicado rechaza sesión pero el bootstrap
      // ya trajo ofertas, seguimos con ese feed (Recommendations suele estar en la lista blanca igual).
      apiBag = null;
      if (kDebugMode &&
          bootstrapMerged != null &&
          bootstrapMerged.orderedOffers.isNotEmpty) {
        debugPrint(
          '[Home feed] Recommendations 401/403 → usando datos del Bootstrap '
          '(${bootstrapMerged.orderedOffers.length} oferta(s)).',
        );
      }
    } catch (_) {
      apiBag = null;
    }

    if (bootstrapMerged != null &&
        apiBag != null &&
        apiBag.offerIds.isNotEmpty) {
      apiBag = _overlayBootstrapFallback(apiBag, bootstrapMerged);
    }

    if (apiBag != null && apiBag.orderedOffers.isNotEmpty) {
      return apiBag;
    }

    if (bootstrapMerged != null && bootstrapMerged.orderedOffers.isNotEmpty) {
      return bootstrapMerged;
    }

    if (apiBag != null) return apiBag;

    try {
      return await RecommendationsService.fetchRecommendations(
        take: take,
        logResponseBody: logRecommendationsResponseBody,
      );
    } on UnauthorizedException {
      if (bootstrapMerged != null &&
          bootstrapMerged.orderedOffers.isNotEmpty) {
        return bootstrapMerged;
      }
      rethrow;
    }
  }

  static List<String> _sliceTakeTrimmed(List<String> ids, int take) {
    if (ids.length <= take) return ids;
    return ids.take(take).toList(growable: false);
  }
}
