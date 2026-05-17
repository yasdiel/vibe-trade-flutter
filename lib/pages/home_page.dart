import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/recommendations_response.dart';
import 'package:vibe_trade_v1/pages/public_offer_page.dart';
import 'package:vibe_trade_v1/pages/public_store_page.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';
import 'package:vibe_trade_v1/services/home_recommendations_loader.dart';
import 'package:vibe_trade_v1/services/recommendations_service.dart';
import 'package:vibe_trade_v1/services/saved_offers_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/home/home_recommended_stores.dart';
import 'package:vibe_trade_v1/widgets/offers/offer_card.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;
  RecommendationsResponse? _data;
  /// Solo sustituye me gustas locales hasta refrescar el feed del servidor.
  final Map<String, OfferModel> _likeOverrides = {};

  @override
  void initState() {
    super.initState();
    SessionService.isLoggedInNotifier.addListener(
      _reloadRecommendationsOnSessionFlip,
    );
    _loadRecommendations();
  }

  @override
  void dispose() {
    SessionService.isLoggedInNotifier.removeListener(
      _reloadRecommendationsOnSessionFlip,
    );
    super.dispose();
  }

  void _reloadRecommendationsOnSessionFlip() {
    if (!mounted) return;
    unawaited(_loadRecommendations());
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await HomeRecommendationsLoader.loadForHome(
        take: RecommendationsService.defaultTake,
        onBootstrapFeedReady: (RecommendationsResponse b) {
          if (!mounted) return;
          setState(() {
            _data = b;
            _likeOverrides.clear();
            _loading = false;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _likeOverrides.clear();
        _loading = false;
      });
    } on UnauthorizedException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  OfferModel _offerForUi(OfferModel entry) {
    final base = _data?.offers[entry.id] ?? entry;
    final o = _likeOverrides[entry.id];
    if (o == null) return base;
    return base.copyWith(
      viewerLikedOffer: o.viewerLikedOffer,
      offerLikeCount: o.offerLikeCount,
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleLike(OfferModel entry) async {
    final base = _data?.offers[entry.id] ?? entry;
    final cur = _offerForUi(entry);
    setState(() {
      _likeOverrides[entry.id] = cur.copyWith(
        viewerLikedOffer: !cur.viewerLikedOffer,
        offerLikeCount: cur.viewerLikedOffer
            ? (cur.offerLikeCount > 0 ? cur.offerLikeCount - 1 : 0)
            : cur.offerLikeCount + 1,
      );
    });
    try {
      final r = await MarketService.toggleOfferLike(entry.id);
      if (!mounted) return;
      setState(() {
        _likeOverrides[entry.id] = base.copyWith(
          viewerLikedOffer: r.liked,
          offerLikeCount: r.likeCount,
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _likeOverrides.remove(entry.id));
      _toast(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toggleSave(OfferModel entry) async {
    final saved = SavedOffersService.idsNotifier.value.contains(entry.id);
    try {
      if (saved) {
        await SavedOffersService.removeOffer(entry.id);
      } else {
        await SavedOffersService.saveOffer(entry.id);
      }
    } catch (error) {
      if (!mounted) return;
      _toast(error.toString().replaceFirst('Exception: ', ''));
      unawaited(SavedOffersService.hydrateFromServer());
    }
  }

  void _onOfferSurfaceTap(BuildContext context, OfferModel entry) {
    unawaited(
      RecommendationsService.postInteraction(
        offerId: entry.id,
        eventType: 'click',
      ),
    );
    final badge = _data?.storeFor(entry);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicOfferPage(
          offerId: entry.id,
          initialStore: badge,
        ),
      ),
    );
  }

  void _openRecommendedStore(BuildContext context, String storeId) {
    final badge = _data?.storeBadges[storeId];
    if (badge == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicStorePage(
          storeId: storeId,
          initialBadge: badge,
        ),
      ),
    );
  }

  /// Rail / FAB: hay `storeBadges` enlazadas al orden actual de `offerIds`.
  bool _recommendedStoresVisible(BuildContext context) =>
      _data?.hasStoreShelfTiles ?? false;

  Widget _recommendedStoresRail(
    RecommendationsResponse d, {
    required double width,
    double? viewportHeight,
  }) {
    return Container(
      width: width,
      height: viewportHeight,
      margin: const EdgeInsets.fromLTRB(12, 0, 8, 0),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark ? 0.35 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Row(
              children: [
                Icon(Icons.storefront_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tiendas recomendadas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.dividerColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 10, 10),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  child: HomeRecommendedStoresList(
                    storeIds: d.storeIdsForHomeShelf(),
                    badges: d.storeBadges,
                    onStoreTap: (sid) =>
                        _openRecommendedStore(context, sid),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _feedSlivers(
    BuildContext context,
    RecommendationsResponse d,
    List<OfferModel> offers,
    Set<String> savedIds,
  ) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        sliver: SliverToBoxAdapter(child: _Header(total: offers.length)),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final cols = _columnsFor(constraints.crossAxisExtent);
            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: _aspectRatioFor(cols),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final offer = offers[index];
                  return OfferCard(
                    key: ValueKey(offer.id),
                    offer: _offerForUi(offer),
                    store: d.storeFor(offer),
                    isBookmarked: savedIds.contains(offer.id),
                    onOpen: () => _onOfferSurfaceTap(context, offer),
                    onLikeTap: () => _toggleLike(offer),
                    onBookmarkTap: () => _toggleSave(offer),
                  );
                },
                childCount: offers.length,
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _desktopBody(BuildContext context, RecommendationsResponse d) {
    final offers = d.orderedOffers;
    final h = MediaQuery.sizeOf(context).height;

    Widget scrollOffers(Set<String> savedIds) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: _feedSlivers(context, d, offers, savedIds),
        );

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadRecommendations,
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: SavedOffersService.idsNotifier,
          builder: (context, savedIds, _) => LayoutBuilder(
            builder: (context, lc) {
              final railHeight = lc.maxHeight.isFinite ? lc.maxHeight : h;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_recommendedStoresVisible(context))
                    _recommendedStoresRail(
                      d,
                      width: 292,
                      viewportHeight: railHeight,
                    ),
                  Expanded(
                    child: scrollOffers(savedIds),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      primary: false,
      backgroundColor: AppTheme.appBgColor,
      floatingActionButton: (_data != null && !isDesktop && _recommendedStoresVisible(context))
          ? FloatingActionButton.extended(
              elevation: 2,
              onPressed: () {
                final d = _data;
                if (d == null) return;
                showRecommendedStoresBottomSheet(
                  context: context,
                  storeIds: d.storeIdsForHomeShelf(),
                  badges: d.storeBadges,
                  onStoreTap: (sid) => _openRecommendedStore(context, sid),
                );
              },
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Tiendas'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _buildInner(context, isDesktop),
    );
  }

  Widget _buildInner(
    BuildContext context,
    bool isDesktop,
  ) {
    if (_loading && _data == null) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _data == null) {
      return SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _loadRecommendations,
          child: _ErrorState(message: _error!, onRetry: _loadRecommendations),
        ),
      );
    }

    final d = _data;
    final offers = d?.orderedOffers ?? const <OfferModel>[];
    if (d == null || offers.isEmpty) {
      return SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _loadRecommendations,
          child: _EmptyState(onRefresh: _loadRecommendations),
        ),
      );
    }

    if (isDesktop && _recommendedStoresVisible(context)) {
      return _desktopBody(context, d);
    }

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadRecommendations,
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: SavedOffersService.idsNotifier,
          builder: (context, savedIds, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: _feedSlivers(context, d, offers, savedIds),
          ),
        ),
      ),
    );
  }

  int _columnsFor(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  double _aspectRatioFor(int columns) {
    switch (columns) {
      case 1:
        return 0.71;
      case 2:
        return 0.63;
      case 3:
        return 0.57;
      default:
        return 0.53;
    }
  }
}

class _Header extends StatelessWidget {
  final int total;

  const _Header({required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.recommend_outlined,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recomendado para ti',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.selectedColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ofertas seleccionadas en base a tu actividad reciente.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Icon(
          Icons.recommend_outlined,
          size: 64,
          color: AppTheme.primaryColor.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Text(
          'Aun no tenemos recomendaciones',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explora la app y guarda ofertas que te interesen para ayudarnos '
          'a personalizar tu feed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Actualizar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      children: [
        Icon(
          Icons.error_outline,
          size: 56,
          color: AppTheme.errorColor,
        ),
        const SizedBox(height: 12),
        Text(
          'No pudimos cargar las recomendaciones',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
