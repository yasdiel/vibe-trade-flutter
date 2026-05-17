import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibe_trade_v1/models/catalog_detail_model.dart';
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/pages/public_offer_page.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';
import 'package:vibe_trade_v1/widgets/serviceConfiguration/service_image_placeholder.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_image_placeholder.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_website_link.dart';

/// Vitrina publica de una tienda. Equivalente al `StorePage` del demo en React
/// (vista de visitante / no-dueno): identidad de la tienda + catalogo
/// publicado (productos, servicios, hojas de ruta).
///
/// Hidrata desde `POST /Market/stores/{id}/detail`.
class PublicStorePage extends StatefulWidget {
  final String storeId;

  /// Snapshot opcional del badge (de busqueda o feed) para pintar la cabecera
  /// mientras carga la respuesta completa.
  final StoreBadgeModel? initialBadge;

  const PublicStorePage({
    super.key,
    required this.storeId,
    this.initialBadge,
  });

  @override
  State<PublicStorePage> createState() => _PublicStorePageState();
}

class _PublicStorePageState extends State<PublicStorePage> {
  StoreDetailResponse? _data;
  StoreBadgeModel? _displayBadge;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayBadge = widget.initialBadge;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail =
          await MarketService.fetchPublicStoreDetail(widget.storeId);
      if (!mounted) return;
      setState(() {
        _data = detail;
        _displayBadge = detail.store;
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

  @override
  Widget build(BuildContext context) {
    final badge = _displayBadge;
    final title = (badge?.name ?? '').trim().isNotEmpty
        ? badge!.name.trim()
        : 'Tienda';

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
          if (_displayBadge != null)
            _StoreHeader(badge: _displayBadge!, owner: null),
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
          Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudo cargar la tienda',
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
    final store = data.store;
    final catalog = data.catalog;
    final pubProducts =
        catalog.products.where((p) => p.published).toList(growable: false);
    final pubServices =
        catalog.services.where((s) => s.published).toList(growable: false);
    final isWide = ResponsiveLayout.isTablet(context);

    final content = <Widget>[
      _StoreHeader(badge: store, owner: data.owner),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _IdentitySection(
          badge: store,
          pitch: catalog.pitch.isNotEmpty ? catalog.pitch : store.pitch,
        ),
      ),
      if (store.location != null) ...[
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _LocationSection(location: store.location!),
        ),
      ],
      const SizedBox(height: 18),
      _SectionHeader(
        icon: Icons.inventory_2_outlined,
        title: 'Productos',
        count: pubProducts.length,
      ),
      if (pubProducts.isEmpty)
        const _EmptyHint(text: 'Esta tienda aun no publica productos.')
      else ...[
        for (final p in pubProducts)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _ProductTile(product: p, store: store),
          ),
      ],
      const SizedBox(height: 18),
      _SectionHeader(
        icon: Icons.handyman_outlined,
        title: 'Servicios',
        count: pubServices.length,
      ),
      if (pubServices.isEmpty)
        const _EmptyHint(text: 'Esta tienda aun no publica servicios.')
      else ...[
        for (final s in pubServices)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _ServiceTile(service: s, store: store),
          ),
      ],
      if (catalog.emergents.isNotEmpty) ...[
        const SizedBox(height: 18),
        _SectionHeader(
          icon: Icons.alt_route_outlined,
          title: 'Hojas de ruta',
          count: catalog.emergents.length,
        ),
        for (final e in catalog.emergents)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _EmergentTile(offer: e, store: store),
          ),
      ],
    ];

    if (isWide) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: content,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Cabecera identidad
// ---------------------------------------------------------------------------

class _StoreHeader extends StatelessWidget {
  final StoreBadgeModel badge;
  final StoreDetailOwnerModel? owner;

  const _StoreHeader({required this.badge, required this.owner});

  String? _resolved(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    return MediaService.resolveMediaUrl(t);
  }

  @override
  Widget build(BuildContext context) {
    final logo = _resolved(badge.avatarUrl);
    final title =
        badge.name.trim().isNotEmpty ? badge.name.trim() : 'Tienda';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 72,
              height: 72,
              child: logo != null
                  ? Image.network(
                      logo,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _storePlaceholder(),
                    )
                  : _storePlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (badge.verified)
                      const _Chip(
                        icon: Icons.verified,
                        text: 'Verificada',
                        kind: _ChipKind.success,
                      ),
                    if (badge.transportIncluded)
                      const _Chip(
                        icon: Icons.local_shipping_outlined,
                        text: 'Transporte',
                        kind: _ChipKind.primary,
                      ),
                    _Chip(
                      icon: Icons.shield_outlined,
                      text: 'Confianza ${badge.trustScore}',
                      kind: _trustChipKind(badge.trustScore),
                    ),
                  ],
                ),
                if (owner != null && owner!.name.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Por ${owner!.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storePlaceholder() {
    return const StoreImagePlaceholder(
      width: 72,
      height: 72,
      iconSize: 36,
      borderRadius: BorderRadius.zero,
    );
  }
}

_ChipKind _trustChipKind(int score) {
  if (score < 30) return _ChipKind.error;
  if (score <= 60) return _ChipKind.warning;
  return _ChipKind.success;
}

enum _ChipKind { success, warning, error, primary, neutral }

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  final _ChipKind kind;

  const _Chip({
    required this.icon,
    required this.text,
    this.kind = _ChipKind.neutral,
  });

  Color get _color {
    switch (kind) {
      case _ChipKind.success:
        return AppTheme.successColor;
      case _ChipKind.warning:
        return AppTheme.warningColor;
      case _ChipKind.error:
        return AppTheme.errorColor;
      case _ChipKind.primary:
        return AppTheme.primaryColor;
      case _ChipKind.neutral:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bloque identidad: categorias, pitch, sitio web
// ---------------------------------------------------------------------------

class _IdentitySection extends StatelessWidget {
  final StoreBadgeModel badge;
  final String pitch;

  const _IdentitySection({required this.badge, required this.pitch});

  @override
  Widget build(BuildContext context) {
    final web = badge.websiteUrl.trim();
    final children = <Widget>[];

    if (badge.categories.isNotEmpty) {
      children.add(Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final c in badge.categories)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.selectedColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                c,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ));
    }
    if (pitch.trim().isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 12));
      children.add(Text(
        pitch.trim(),
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
          height: 1.45,
        ),
      ));
    }
    if (web.isNotEmpty) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(StoreWebsiteLink(url: web, showIcon: true));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final StoreLocation location;

  const _LocationSection({required this.location});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(location.latitude, location.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 14,
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.vibetrade.vibe_trade_v1',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.selectedColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas de items del catalogo
// ---------------------------------------------------------------------------

class _ProductTile extends StatelessWidget {
  final StoreProductCatalogRowModel product;
  final StoreBadgeModel store;

  const _ProductTile({required this.product, required this.store});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.photoUrls.isNotEmpty
        ? MediaService.resolveMediaUrl(product.photoUrls.first)
        : null;

    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openOffer(context, product.id, store, imageUrl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(url: imageUrl, fallbackIcon: Icons.inventory_2_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((product.category ?? '').isNotEmpty)
                      Text(
                        product.category!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      product.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.displayPrice,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if ((product.shortDescription ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        product.shortDescription!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final StoreServiceCatalogRowModel service;
  final StoreBadgeModel store;

  const _ServiceTile({required this.service, required this.store});

  @override
  Widget build(BuildContext context) {
    final imageUrl = service.photoUrls.isNotEmpty
        ? MediaService.resolveMediaUrl(service.photoUrls.first)
        : null;

    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openOffer(context, service.id, store, imageUrl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child:
                      imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const ServiceImagePlaceholder(
                                  iconSize: 28,
                                  borderRadius: BorderRadius.zero,
                                ),
                          )
                          : const ServiceImagePlaceholder(
                            iconSize: 28,
                            borderRadius: BorderRadius.zero,
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((service.category ?? '').isNotEmpty)
                      Text(
                        service.category!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      service.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if ((service.descripcion ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        service.descripcion!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (service.monedas.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final m in service.monedas)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.selectedColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergentTile extends StatelessWidget {
  final OfferModel offer;
  final StoreBadgeModel store;

  const _EmergentTile({required this.offer, required this.store});

  @override
  Widget build(BuildContext context) {
    final raw = offer.imageUrl ??
        (offer.imageUrls.isNotEmpty ? offer.imageUrls.first : null);
    final imageUrl =
        raw != null && raw.isNotEmpty ? MediaService.resolveMediaUrl(raw) : null;

    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openOffer(context, offer.id, store, imageUrl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(url: imageUrl, fallbackIcon: Icons.alt_route_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title.isNotEmpty
                          ? offer.title
                          : 'Hoja de ruta',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      offer.price.isNotEmpty
                          ? offer.price
                          : (offer.currency.isNotEmpty ? offer.currency : '-'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (offer.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        offer.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;

  const _Thumb({required this.url, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
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
    return Container(
      color: AppTheme.surfaceMutedColor,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: 26,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

void _openOffer(
  BuildContext context,
  String offerId,
  StoreBadgeModel store,
  String? imageUrl,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PublicOfferPage(
        offerId: offerId,
        initialStore: store,
      ),
    ),
  );
}
