import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/pages/products_page.dart';
import 'package:vibe_trade_v1/pages/services_page.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/new_store_modal.dart';

class StoreDetailPage extends StatelessWidget {
  final String storeId;

  const StoreDetailPage({super.key, required this.storeId});

  Future<void> _openEdit(BuildContext context, StoreModel store) async {
    await showNewStoreModal(context, initialStore: store);
  }

  Future<void> _confirmDelete(BuildContext context, StoreModel store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar tienda'),
        content: Text(
          'Seguro que quieres eliminar la tienda "${store.name}"? Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await StoreService.deleteStore(store.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tienda "${store.name}" eliminada')),
    );
  }

  String _formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(date.day)}/${pad(date.month)}/${date.year}';
  }

  Color _trustColor(int value) {
    if (value < 30) return AppTheme.errorColor;
    if (value <= 60) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StoreModel>>(
      valueListenable: StoreService.storesNotifier,
      builder: (context, stores, _) {
        StoreModel? matched;
        for (final candidate in stores) {
          if (candidate.id == storeId) {
            matched = candidate;
            break;
          }
        }

        if (matched == null) {
          return Scaffold(
            backgroundColor: AppTheme.appBgColor,
            appBar: AppBar(
              backgroundColor: AppTheme.foregroundColor,
              foregroundColor: AppTheme.textPrimary,
              elevation: 1,
              title: const Text('Tienda'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'La tienda ya no existe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          );
        }

        final StoreModel store = matched;

        return Scaffold(
          backgroundColor: AppTheme.appBgColor,
          appBar: AppBar(
            backgroundColor: AppTheme.foregroundColor,
            foregroundColor: AppTheme.textPrimary,
            elevation: 1,
            title: Text(
              store.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Editar tienda',
                onPressed: () => _openEdit(context, store),
                icon: Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
              ),
              IconButton(
                tooltip: 'Eliminar tienda',
                onPressed: () => _confirmDelete(context, store),
                icon: Icon(
                  Icons.delete_outline,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              final detailsCard = _InfoCard(
                title: 'Detalles',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Registrada el',
                      value: _formatDate(store.createdAt),
                    ),
                    _InfoRow(
                      icon: Icons.local_shipping_outlined,
                      label: 'Transporte propio',
                      value: store.hasOwnTransport ? 'Si' : 'No',
                    ),
                    if (store.website.isNotEmpty)
                      _InfoRow(
                        icon: Icons.public_outlined,
                        label: 'Sitio web',
                        value: store.website,
                      ),
                    _InfoRow(
                      icon: store.isVerified
                          ? Icons.verified
                          : Icons.error_outline,
                      label: 'Estado',
                      value: store.isVerified
                          ? 'Verificada'
                          : 'No verificada',
                      valueColor: store.isVerified
                          ? AppTheme.successColor
                          : AppTheme.textSecondary,
                    ),
                  ],
                ),
              );

              final categoriesCard = store.categories.isNotEmpty
                  ? _InfoCard(
                      title: 'Categorias',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in store.categories)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.selectedColor,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : null;

              final descriptionCard = store.description.isNotEmpty
                  ? _InfoCard(
                      title: 'Descripcion',
                      child: Text(
                        store.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    )
                  : null;

              final mapCard = store.hasLocation
                  ? _LocationPreview(
                      latitude: store.latitude!,
                      longitude: store.longitude!,
                    )
                  : null;

              final catalogSection = _CatalogSection(
                icon: Icons.inventory_2_outlined,
                title: 'Catalogo',
                count: store.productsCount,
                unitSingular: 'producto',
                unitPlural: 'productos',
                description:
                    'Gestiona los productos que tu tienda vende desde su catalogo.',
                buttonLabel: 'Abrir catalogo',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProductsPage(storeId: store.id),
                    ),
                  );
                },
              );

              final servicesSection = _CatalogSection(
                icon: Icons.handyman_outlined,
                title: 'Servicios',
                count: store.servicesCount,
                unitSingular: 'servicio',
                unitPlural: 'servicios',
                description:
                    'Administra los servicios que ofreces desde tu tienda.',
                buttonLabel: 'Abrir servicios',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ServicesPage(storeId: store.id),
                    ),
                  );
                },
              );

              final children = <Widget>[
                _StoreHero(store: store),
                const SizedBox(height: 16),
                _TrustSection(
                  score: store.trustScore,
                  color: _trustColor(store.trustScore),
                ),
                const SizedBox(height: 16),
                if (isWide && categoriesCard != null)
                  _SideBySide(
                    left: detailsCard,
                    right: categoriesCard,
                  )
                else ...[
                  detailsCard,
                  if (categoriesCard != null) ...[
                    const SizedBox(height: 16),
                    categoriesCard,
                  ],
                ],
                if (descriptionCard != null) ...[
                  const SizedBox(height: 16),
                  descriptionCard,
                ],
                if (mapCard != null) ...[
                  const SizedBox(height: 16),
                  mapCard,
                ],
                const SizedBox(height: 16),
                if (isWide)
                  _SideBySide(
                    left: catalogSection,
                    right: servicesSection,
                  )
                else ...[
                  catalogSection,
                  const SizedBox(height: 16),
                  servicesSection,
                ],
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SideBySide extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double spacing;

  const _SideBySide({
    required this.left,
    required this.right,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          SizedBox(width: spacing),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _CatalogSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final String unitSingular;
  final String unitPlural;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _CatalogSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.unitSingular,
    required this.unitPlural,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final unit = count == 1 ? unitSingular : unitPlural;

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
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.selectedColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count $unit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
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

class _StoreHero extends StatelessWidget {
  final StoreModel store;

  const _StoreHero({required this.store});

  Widget _buildImage() {
    final path = store.imagePath;
    if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    final letter = store.name.trim().isNotEmpty
        ? store.name.trim()[0].toUpperCase()
        : 'T';
    return Container(
      height: 180,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 72,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          _buildImage(),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: store.isVerified
                    ? AppTheme.successColor.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    store.isVerified ? Icons.verified : Icons.error_outline,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    store.isVerified ? 'Verificada' : 'No verificada',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  final int score;
  final Color color;

  const _TrustSection({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confianza de la tienda',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: score.clamp(0, 100) / 100,
              backgroundColor: AppTheme.surfaceMutedColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPreview extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _LocationPreview({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
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
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      size: 40,
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
