import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/pages/public_offer_page.dart';
import 'package:vibe_trade_v1/pages/public_store_page.dart';
import 'package:vibe_trade_v1/services/catalog_search_service.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_image_placeholder.dart';

/// Formatea distancias en km o metros
String formatKilometers(double v) {
  if (v < 1) return '${(v * 1000).round()} m';
  if (v < 10) return '${v.toStringAsFixed(1)} km';
  return '${v.round()} km';
}

/// Tarjeta principal que contiene la búsqueda resultante
class ResultCard extends StatelessWidget {
  final CatalogSearchItem item;

  const ResultCard({required this.item});

  void _openStore(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PublicStorePage(storeId: item.store.id, initialBadge: item.store),
      ),
    );
  }

  void _openOffer(BuildContext context) {
    final offer = item.offer;
    if (offer == null) {
      _openStore(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PublicOfferPage(offerId: offer.id, initialStore: item.store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStore = item.kind == CatalogSearchKind.store || item.offer == null;
    final body = isStore
        ? StoreResultCard(
            store: item.store,
            publishedProducts: item.publishedProducts,
            publishedServices: item.publishedServices,
            distanceKm: item.distanceKm,
          )
        : OfferResultCard(
            store: item.store,
            offer: item.offer!,
            distanceKm: item.distanceKm,
          );

    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => isStore ? _openStore(context) : _openOffer(context),
        child: body,
      ),
    );
  }
}

/// Tarjeta para mostrar información de una tienda
class StoreResultCard extends StatelessWidget {
  final StoreBadgeModel store;
  final int publishedProducts;
  final int publishedServices;
  final double? distanceKm;

  const StoreResultCard({
    required this.store,
    required this.publishedProducts,
    required this.publishedServices,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarBox(
            url: store.avatarUrl,
            fallbackIcon: Icons.storefront_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name.isEmpty ? 'Tienda' : store.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (store.verified)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: AppTheme.successColor,
                        ),
                      ),
                  ],
                ),
                if (store.categories.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    store.categories.join(' . '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    MetaChip(
                      icon: Icons.inventory_2_outlined,
                      text: '$publishedProducts',
                    ),
                    MetaChip(
                      icon: Icons.handyman_outlined,
                      text: '$publishedServices',
                    ),
                    if (distanceKm != null)
                      MetaChip(
                        icon: Icons.place_outlined,
                        text: formatKilometers(distanceKm!),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TrustBar(score: store.trustScore),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta para mostrar información de una oferta específica
class OfferResultCard extends StatelessWidget {
  final StoreBadgeModel store;
  final CatalogSearchOffer offer;
  final double? distanceKm;

  const OfferResultCard({
    required this.store,
    required this.offer,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = offer.photoUrls.isNotEmpty
        ? MediaService.resolveMediaUrl(offer.photoUrls.first)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarBox(
            url: imageUrl,
            fallbackIcon: offer.kind == CatalogSearchKind.service
                ? Icons.handyman_outlined
                : offer.kind == CatalogSearchKind.emergent
                ? Icons.alt_route_outlined
                : Icons.inventory_2_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    KindPill(kind: offer.kind),
                    const SizedBox(width: 6),
                    if (offer.category.isNotEmpty)
                      Flexible(
                        child: Text(
                          offer.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  offer.name.isEmpty ? 'Sin titulo' : offer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (offer.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    offer.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                PriceRow(offer: offer),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name.isEmpty ? 'Tienda' : store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (distanceKm != null)
                      MetaChip(
                        icon: Icons.place_outlined,
                        text: formatKilometers(distanceKm!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de precios con monedas aceptadas
class PriceRow extends StatelessWidget {
  final CatalogSearchOffer offer;

  const PriceRow({required this.offer});

  @override
  Widget build(BuildContext context) {
    final price = offer.price.isNotEmpty
        ? offer.price
        : (offer.currency.isNotEmpty ? offer.currency : '-');

    final extras = offer.acceptedCurrencies
        .where((c) => c.isNotEmpty && c != offer.currency)
        .toList(growable: false);

    return Row(
      children: [
        Flexible(
          child: Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              height: 1.05,
            ),
          ),
        ),
        if (extras.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.selectedColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+ ${extras.join(' / ')}',
              style: TextStyle(
                fontSize: 10,
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

/// Etiqueta que indica el tipo de búsqueda (Producto, Servicio, Ruta)
class KindPill extends StatelessWidget {
  final CatalogSearchKind kind;

  const KindPill({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.selectedColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        kind.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Chip que muestra metadatos (productos, servicios, distancia)
class MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Barra de confianza que muestra el score de trust
class TrustBar extends StatelessWidget {
  final int score;

  const TrustBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final v = score.clamp(0, 100);
    final color = v < 30
        ? AppTheme.errorColor
        : v <= 60
        ? AppTheme.warningColor
        : AppTheme.successColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              'Confianza',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              '$v%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: v / 100,
            backgroundColor: AppTheme.surfaceMutedColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Avatar/imagen con fallback
class AvatarBox extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;

  const AvatarBox({required this.url, required this.fallbackIcon});

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _size,
        height: _size,
        child: (url != null && url!.isNotEmpty)
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppTheme.surfaceMutedColor,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    if (fallbackIcon == Icons.storefront_outlined) {
      return const StoreImagePlaceholder(
        width: _size,
        height: _size,
        iconSize: 28,
        borderRadius: BorderRadius.zero,
      );
    }
    return Container(
      color: AppTheme.surfaceMutedColor,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 24, color: AppTheme.textSecondary),
    );
  }
}
