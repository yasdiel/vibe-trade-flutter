import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/main_tab_bus.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/saved_offers_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/offers/offer_card.dart';

class SavedOfferts extends StatefulWidget {
  const SavedOfferts({super.key});

  @override
  State<SavedOfferts> createState() => _SavedOffertsState();
}

class _SavedOffertsState extends State<SavedOfferts> {
  bool _busy = false;
  String? _error;
  WorkspaceMarketSnapshot _catalog = const WorkspaceMarketSnapshot(
    offers: {},
    stores: {},
  );

  @override
  void initState() {
    super.initState();
    SavedOffersService.idsNotifier.addListener(_handleSavedChanged);
    unawaited(SavedOffersService.hydrateFromServer());
    unawaited(_loadCatalog(showOverlay: false));
  }

  @override
  void dispose() {
    SavedOffersService.idsNotifier.removeListener(_handleSavedChanged);
    super.dispose();
  }

  void _handleSavedChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadCatalog({required bool showOverlay}) async {
    if (showOverlay) {
      setState(() => _busy = true);
    }
    setState(() => _error = null);
    try {
      final snap = await MarketService.fetchWorkspaceMarketMaps();
      if (!mounted) return;
      setState(() {
        _catalog = snap;
        _busy = false;
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'Inicia sesion para cargar los datos del mercado y ver las fichas completas.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _reloadAll() async {
    await SavedOffersService.hydrateFromServer();
    await _loadCatalog(showOverlay: true);
  }

  List<OfferModel> _cardsFor(Set<String> saved) {
    final out = <OfferModel>[];
    for (final id in saved) {
      final parsed = _catalog.offers[id];
      if (parsed != null) {
        out.add(parsed);
      }
    }
    return out;
  }

  Future<void> _toggleSave(OfferModel offer) async {
    await SavedOffersService.removeOffer(offer.id);
    if (!mounted) return;
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: SavedOffersService.idsNotifier,
      builder: (context, savedIds, _) {
        final ids = SavedOffersService.idsNotifier.value;
        final offers = _cardsFor(ids);
        final showMissing =
            savedIds.isNotEmpty && !_busy && offers.length < savedIds.length;

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: _reloadAll,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1200
                  ? 4
                  : constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 600
                          ? 2
                          : 1;
              const spacing = 14.0;

              double tileWidth() {
                final w = constraints.maxWidth;
                if (cols <= 1) return w.clamp(0, double.infinity);
                final usable = w - spacing * (cols - 1);
                return usable / cols;
              }

              final ar = _aspectRatioFor(cols);
              final tileW = tileWidth();
              final tileH = tileW / ar;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _Header(busy: _busy, savedCount: savedIds.length),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.errorColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (savedIds.isEmpty)
                    _EmptySaved(onExplore: () => MainTabBus.selectTab?.call(0)),
                  if (showMissing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Algunas ofertas guardadas no aparecen en el mercado cargado '
                        '(puede faltar republicarlas en el servidor). '
                        "${savedIds.length - offers.length} sin ficha.",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (_busy && offers.isEmpty)
                    const SizedBox(height: 48),
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: offers.map((o) {
                      final store = _catalog.stores[o.storeId];
                      return SizedBox(
                        width: tileW.clamp(0, double.infinity),
                        height: tileH.clamp(0, double.infinity),
                        child: OfferCard(
                          offer: o,
                          store: store,
                          isBookmarked: true,
                          showInteractions: false,
                          onBookmarkTap: () => _toggleSave(o),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool busy;
  final int savedCount;

  const _Header({required this.busy, required this.savedCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: AppTheme.isDark ? 0.4 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ofertas guardadas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  busy ? 'Actualizando catalogo...' : '$savedCount sincronizadas con tu cuenta.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  final VoidCallback onExplore;

  const _EmptySaved({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppTheme.selectedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.foregroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_offer_outlined,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes ofertas guardadas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'En Home toca el marcador en una recomendacion; se guardara en tu cuenta '
            'y aparecera en esta lista.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text(
                'Ir al Home',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
