import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class OfferCard extends StatelessWidget {
  final OfferModel offer;
  final StoreBadgeModel? store;
  final bool isBookmarked;
  /// Si es false no se muestran me gustas, conteo de comentarios ni badge en la foto.
  final bool showInteractions;
  final VoidCallback? onOpen;
  final Future<void> Function()? onLikeTap;
  final Future<void> Function()? onBookmarkTap;

  const OfferCard({
    super.key,
    required this.offer,
    required this.store,
    this.isBookmarked = false,
    this.showInteractions = true,
    this.onOpen,
    this.onLikeTap,
    this.onBookmarkTap,
  });

  String? get _resolvedImageUrl {
    final candidates = <String?>[
      offer.imageUrl,
      if (offer.imageUrls.isNotEmpty) offer.imageUrls.first,
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      return MediaService.resolveMediaUrl(trimmed);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: onOpen != null
          ? InkWell(
              onTap: onOpen,
              child: _cardBody(context),
            )
          : _cardBody(context),
    );
  }

  Widget _cardBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              _OfferImage(
                imageUrl: _resolvedImageUrl,
                fallbackLetter: offer.title.trim().isNotEmpty
                    ? offer.title.trim()[0].toUpperCase()
                    : 'O',
                isService: offer.isService,
                liked:
                    showInteractions && offer.viewerLikedOffer,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (offer.primaryCategoryTag != null)
                      Text(
                        offer.primaryCategoryTag!.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      offer.title.isNotEmpty
                          ? offer.title
                          : 'Oferta sin titulo',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PriceRow(offer: offer),
                    if (offer.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        offer.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (store != null) _StoreRow(store: store!),
                    const SizedBox(height: 10),
                    _StatsRow(
                      offer: offer,
                      isBookmarked: isBookmarked,
                      showInteractions: showInteractions,
                      onLikeTap: onLikeTap,
                      onBookmarkTap: onBookmarkTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _OfferImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackLetter;
  final bool isService;
  final bool liked;

  const _OfferImage({
    required this.imageUrl,
    required this.fallbackLetter,
    required this.isService,
    required this.liked,
  });

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
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppTheme.subtleSurfaceColor,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stack) =>
                  _buildFallback(),
            )
          else
            _buildFallback(),
          if (isService)
            Positioned(
              left: 10,
              top: 10,
              child: _Pill(
                icon: Icons.handyman_outlined,
                text: 'Servicio',
              ),
            ),
          if (liked)
            Positioned(
              right: 10,
              top: 10,
              child: _Pill(
                icon: Icons.favorite,
                text: 'Te gusta',
                background: Colors.black.withValues(alpha: 0.55),
                foreground: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
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
      child: Text(
        fallbackLetter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? background;
  final Color? foreground;

  const _Pill({
    required this.icon,
    required this.text,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppTheme.primaryColor;
    final bg = background ?? AppTheme.foregroundColor.withValues(alpha: 0.92);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.1,
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
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              height: 1.05,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (extraCurrencies.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.selectedColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+ ${extraCurrencies.join(' / ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StoreRow extends StatelessWidget {
  final StoreBadgeModel store;

  const _StoreRow({required this.store});

  @override
  Widget build(BuildContext context) {
    final rawLogo = store.avatarUrl?.trim();
    final resolvedLogo = (rawLogo != null && rawLogo.isNotEmpty)
        ? MediaService.resolveMediaUrl(rawLogo)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          _StoreLogoChip(resolvedUrl: resolvedLogo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              store.name.isNotEmpty ? store.name : 'Tienda',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (store.verified) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.verified,
              size: 14,
              color: AppTheme.successColor,
            ),
          ],
          if (store.transportIncluded) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'Transporte incluido',
              child: Icon(
                Icons.local_shipping_outlined,
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
          const SizedBox(width: 6),
          _TrustChip(score: store.trustScore),
        ],
      ),
    );
  }
}

class _StoreLogoChip extends StatelessWidget {
  final String? resolvedUrl;

  const _StoreLogoChip({required this.resolvedUrl});

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    if (resolvedUrl != null && resolvedUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: _size,
          height: _size,
          child: Image.network(
            resolvedUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: _size,
                height: _size,
                color: AppTheme.subtleSurfaceColor,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stack) => _fallbackIcon(),
          ),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        size: 18,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final int score;

  const _TrustChip({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppTheme.successColor
        : (score >= 60 ? AppTheme.warningColor : AppTheme.errorColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final OfferModel offer;
  final bool isBookmarked;
  final bool showInteractions;
  final Future<void> Function()? onLikeTap;
  final Future<void> Function()? onBookmarkTap;

  const _StatsRow({
    required this.offer,
    required this.isBookmarked,
    required this.showInteractions,
    this.onLikeTap,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    Future<void> run(Future<void> Function()? fn) async {
      if (fn == null) return;
      await fn();
    }

    if (!showInteractions) {
      if (onBookmarkTap == null) return const SizedBox.shrink();
      return Row(
        children: [
          const Spacer(),
          Tooltip(
            message: 'Quitar de guardados',
            child: SizedBox(
              height: 32,
              width: 32,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => run(onBookmarkTap),
                child: Icon(
                  Icons.bookmark_remove_outlined,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Tooltip(
          message: 'Me gusta',
          child: SizedBox(
            height: 32,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => run(onLikeTap),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: _IconStat(
                  icon: offer.viewerLikedOffer
                      ? Icons.favorite
                      : Icons.favorite_border,
                  count: offer.offerLikeCount,
                  color: offer.viewerLikedOffer
                      ? AppTheme.errorColor
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        _IconStat(
          icon: Icons.chat_bubble_outline,
          count: offer.publicCommentCount,
          color: AppTheme.textSecondary,
        ),
        const Spacer(),
        Tooltip(
          message: isBookmarked ? 'Quitar de guardados' : 'Guardar',
          child: SizedBox(
            height: 32,
            width: 32,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => run(onBookmarkTap),
              child: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
                color: isBookmarked
                    ? AppTheme.primaryColor
                    : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconStat extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _IconStat({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
