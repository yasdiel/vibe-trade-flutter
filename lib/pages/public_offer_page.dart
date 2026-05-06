import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/catalog_detail_model.dart';
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/pages/chat_thread_page.dart';
import 'package:vibe_trade_v1/pages/public_store_page.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/chat_service.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/services/purchase_interest_intro_service.dart';
import 'package:vibe_trade_v1/services/recommendations_service.dart';
import 'package:vibe_trade_v1/services/saved_offers_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Detalle publico de una oferta. Equivalente al `OfferPage` del demo en React,
/// hidratado desde `GET /Market/offers/{id}/card`.
///
/// Muestra:
///   - galeria de fotos (si hay varias)
///   - titulo, categoria, precio + monedas aceptadas
///   - descripcion / Q&A (resumen)
///   - chip de tienda con boton para abrir la vitrina publica
///   - acciones de like y guardar (si hay sesion)
class PublicOfferPage extends StatefulWidget {
  final String offerId;

  /// Snapshot opcional de la tienda dueña, para pintar mientras carga.
  final StoreBadgeModel? initialStore;

  const PublicOfferPage({
    super.key,
    required this.offerId,
    this.initialStore,
  });

  @override
  State<PublicOfferPage> createState() => _PublicOfferPageState();
}

class _PublicOfferPageState extends State<PublicOfferPage> {
  PublicOfferCardResponse? _data;
  bool _loading = true;
  String? _error;
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
    unawaited(
      RecommendationsService.postInteraction(
        offerId: widget.offerId,
        eventType: 'click',
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MarketService.fetchPublicOfferCard(widget.offerId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _galleryIndex = 0;
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

  Future<void> _toggleLike(OfferModel offer) async {
    try {
      final r = await MarketService.toggleOfferLike(offer.id);
      if (!mounted) return;
      setState(() {
        _data = PublicOfferCardResponse(
          offer: offer.copyWith(
            viewerLikedOffer: r.liked,
            offerLikeCount: r.likeCount,
          ),
          store: _data!.store,
        );
      });
    } on UnauthorizedException {
      _toast('Inicia sesion para dar me gusta.');
    } catch (error) {
      _toast(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _toggleSave(OfferModel offer, bool currentlySaved) async {
    try {
      if (currentlySaved) {
        await SavedOffersService.removeOffer(offer.id);
      } else {
        await SavedOffersService.saveOffer(offer.id);
      }
    } on UnauthorizedException {
      _toast('Inicia sesion para guardar ofertas.');
    } catch (error) {
      _toast(error.toString().replaceFirst('Exception: ', ''));
      unawaited(SavedOffersService.hydrateFromServer());
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _comprarConfirmMessage(OfferModel offer) {
    final kind = catalogItemKind(offer);
    final n = collectOfferPublishedPhotoUrls(offer).length;
    final t = offer.title.trim().isNotEmpty ? offer.title.trim() : 'la oferta';
    var tipoPapel = 'oferta';
    if (kind == CatalogItemKind.product) tipoPapel = 'producto';
    if (kind == CatalogItemKind.service) tipoPapel = 'servicio';
    final fotos = n > 0
        ? ' Las fotos publicadas en la ficha ($n) se envían en el mismo mensaje que el texto.'
        : ' Si no hay fotos de ficha, el mensaje solo incluye el texto, con el detalle adecuado al tipo (producto o servicio).';
    return 'Se creará un chat nuevo y el vendedor recibirá un aviso. El primer mensaje dirá que tienes interés en el $tipoPapel «$t», teniendo en cuenta el tipo y el título de la oferta en la plataforma.$fotos';
  }

  bool get _isOwnOffer {
    final data = _data;
    if (data == null) return false;
    final me = SessionService.currentUserNotifier.value;
    final owner = data.store.ownerUserId.trim();
    if (owner.isEmpty || me == null || me.id.isEmpty) return false;
    return owner == me.id.trim();
  }

  Future<void> _openComprarChatFlow(OfferModel offer, StoreBadgeModel store) async {
    final token = await SessionService.getSavedToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      await Navigator.of(context).pushNamed('/signin');
      return;
    }
    final me = SessionService.currentUserNotifier.value;
    if (me == null || me.id.isEmpty) {
      if (!mounted) return;
      await Navigator.of(context).pushNamed('/signin');
      return;
    }
    if (_isOwnOffer) {
      _toast('No puedes chatear contigo mismo.');
      return;
    }
    if (!mounted) return;

    final navigatorContext = context;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var busy = false;
        return StatefulBuilder(
          builder: (dialogSetContext, setLocal) {
            return AlertDialog(
              title: const Text('Iniciar chat con la tienda'),
              content: SingleChildScrollView(
                child: Text(_comprarConfirmMessage(offer)),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setLocal(() => busy = true);
                          try {
                            final dto = await ChatService.createOrGetChatThread(
                              offerId: offer.catalogThreadOfferId,
                              purchaseIntent: true,
                              forceNew: true,
                            );
                            final threadId =
                                (dto['id'] ?? dto['Id'])?.toString().trim() ?? '';
                            if (!threadId.startsWith('cth_')) {
                              if (dialogSetContext.mounted) {
                                _toast('No se pudo abrir el chat. Prueba de nuevo.');
                              }
                              return;
                            }
                            try {
                              await sendPurchaseInterestIntro(threadId, offer);
                            } catch (_) {
                              if (dialogSetContext.mounted) {
                                _toast(
                                  'El chat se abrió, pero el primer mensaje no pudo enviarse. Escribe desde el chat.',
                                );
                              }
                            }
                            unawaited(
                              RecommendationsService.postInteraction(
                                offerId: offer.id,
                                eventType: 'chat_start',
                              ),
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            if (!mounted) return;
                            if (!navigatorContext.mounted) return;
                            await Navigator.of(navigatorContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ChatThreadPage(
                                  threadId: threadId,
                                  storeName: store.name,
                                ),
                              ),
                            );
                          } on ChatCannotMessageSelfException {
                            if (mounted) {
                              _toast('No puedes chatear contigo mismo.');
                            }
                          } catch (e) {
                            if (mounted) {
                              _toast(
                                e.toString().replaceFirst('Exception: ', ''),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setLocal(() => busy = false);
                            }
                          }
                        },
                  child: busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Theme.of(dialogSetContext).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Sí, abrir chat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onEmergentSubscribeTap() {
    _toast(
      'Suscripción a rutas emergentes: en la demo web elige tramo y servicio de transporte. Pronto en la app.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _data?.offer;
    final title = (offer?.title ?? '').trim().isNotEmpty
        ? offer!.title.trim()
        : 'Oferta';

    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.foregroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ],
      );
    }
    if (_error != null && _data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
          const SizedBox(height: 8),
          Text(
            'No se pudo cargar la oferta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? '',
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
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    final data = _data!;
    final offer = data.offer;
    final store = data.store;
    final gallery = _allImages(offer);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _Hero(
          imageUrl: gallery.isNotEmpty
              ? MediaService.resolveMediaUrl(gallery[_galleryIndex])
              : null,
          isService: offer.isService,
        ),
        if (gallery.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: gallery.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = MediaService.resolveMediaUrl(gallery[i]);
                  final selected = i == _galleryIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _galleryIndex = i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryColor
                                : AppTheme.dividerColor,
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surfaceMutedColor,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (offer.primaryCategoryTag != null)
                Text(
                  offer.primaryCategoryTag!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.7,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                offer.title.isNotEmpty ? offer.title : 'Oferta sin titulo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _PriceRow(offer: offer),
              const SizedBox(height: 16),
              _ActionsRow(
                offer: offer,
                onLikeTap: () => _toggleLike(offer),
                onSaveTap: (saved) => _toggleSave(offer, saved),
              ),
              if (offer.description.trim().isNotEmpty) ...[
                const SizedBox(height: 18),
                _Card(
                  title: 'Descripcion',
                  child: Text(
                    offer.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _StoreCallout(
                store: store,
                onOpen: () => _openStore(context, store),
              ),
              if (offer.tags.length > 1) ...[
                const SizedBox(height: 16),
                _Card(
                  title: 'Etiquetas',
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in offer.tags.skip(1))
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
                            t,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ValueListenableBuilder<UserProfileModel?>(
                valueListenable: SessionService.currentUserNotifier,
                builder: (context, me, _) {
                  final owner = store.ownerUserId.trim();
                  final ownOffer = owner.isNotEmpty &&
                      me != null &&
                      me.id.isNotEmpty &&
                      owner == me.id.trim();
                  return SizedBox(
                    width: double.infinity,
                    child: offer.isEmergentRoutePublication
                        ? FilledButton.icon(
                            onPressed: ownOffer ? null : _onEmergentSubscribeTap,
                            icon: const Icon(Icons.route_outlined, size: 18),
                            label: const Text('Suscribirse'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: ownOffer
                                ? null
                                : () => _openComprarChatFlow(offer, store),
                            icon:
                                const Icon(Icons.shopping_cart_outlined, size: 18),
                            label: const Text('Comprar (Chat)'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<String> _allImages(OfferModel offer) {
    final out = <String>[];
    if ((offer.imageUrl ?? '').trim().isNotEmpty) out.add(offer.imageUrl!.trim());
    for (final url in offer.imageUrls) {
      if (url.trim().isEmpty) continue;
      if (!out.contains(url.trim())) out.add(url.trim());
    }
    return out;
  }
}

void _openStore(BuildContext context, StoreBadgeModel badge) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PublicStorePage(
        storeId: badge.id,
        initialBadge: badge,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Bloques visuales
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  final String? imageUrl;
  final bool isService;

  const _Hero({required this.imageUrl, required this.isService});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppTheme.surfaceMutedColor,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              },
            )
          else
            _fallback(),
          if (isService)
            const Positioned(
              left: 12,
              top: 12,
              child: _ServicePill(),
            ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isService
              ? const [Color(0xFF22C55E), Color(0xFF14B8A6)]
              : const [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        isService ? Icons.handyman_outlined : Icons.shopping_bag_outlined,
        size: 64,
        color: Colors.white.withValues(alpha: 0.85),
      ),
    );
  }
}

class _ServicePill extends StatelessWidget {
  const _ServicePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.handyman_outlined, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Servicio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final OfferModel offer;

  const _PriceRow({required this.offer});

  @override
  Widget build(BuildContext context) {
    final extraCurrencies = offer.acceptedCurrencies
        .where((c) => c.isNotEmpty && c != offer.currency)
        .toList(growable: false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            offer.price.isNotEmpty
                ? offer.price
                : (offer.currency.isNotEmpty ? offer.currency : '-'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              letterSpacing: -0.4,
              height: 1.05,
            ),
          ),
        ),
        if (extraCurrencies.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.selectedColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+ ${extraCurrencies.join(' / ')}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final OfferModel offer;
  final VoidCallback onLikeTap;
  final void Function(bool currentlySaved) onSaveTap;

  const _ActionsRow({
    required this.offer,
    required this.onLikeTap,
    required this.onSaveTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: SavedOffersService.idsNotifier,
      builder: (context, savedIds, _) {
        final isSaved = savedIds.contains(offer.id);
        return Row(
          children: [
            OutlinedButton.icon(
              onPressed: onLikeTap,
              icon: Icon(
                offer.viewerLikedOffer
                    ? Icons.favorite
                    : Icons.favorite_border,
                size: 18,
                color: offer.viewerLikedOffer
                    ? AppTheme.errorColor
                    : AppTheme.textSecondary,
              ),
              label: Text(
                '${offer.offerLikeCount}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => onSaveTap(isSaved),
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 18,
                color: isSaved
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
              label: Text(
                isSaved ? 'Guardada' : 'Guardar',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color:
                      isSaved ? AppTheme.primaryColor : AppTheme.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${offer.publicCommentCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StoreCallout extends StatelessWidget {
  final StoreBadgeModel store;
  final VoidCallback onOpen;

  const _StoreCallout({required this.store, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final logo = store.avatarUrl;
    final url = (logo != null && logo.trim().isNotEmpty)
        ? MediaService.resolveMediaUrl(logo.trim())
        : null;

    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: url != null
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(),
                        )
                      : _fallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name.isNotEmpty ? store.name : 'Tienda',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Confianza ${store.trustScore}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (store.verified) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.verified,
                            size: 12,
                            color: AppTheme.successColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppTheme.surfaceMutedColor,
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        size: 22,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
