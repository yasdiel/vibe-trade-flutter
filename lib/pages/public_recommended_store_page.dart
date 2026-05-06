import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Ficha publica al abrir una tienda desde recomendaciones.
///
/// Contrato servidor: mismo JSON que [`MarketCatalogStoreBadgeJson`] en backend
/// (`id`, `name`, `verified`, `transportIncluded`, `trustScore`, `ownerUserId`,
/// `categories`, `avatarUrl?`, `location?` { `lat`,`lng` }, `pitch?`, `websiteUrl?`).
class PublicRecommendedStorePage extends StatelessWidget {
  final StoreBadgeModel badge;

  const PublicRecommendedStorePage({super.key, required this.badge});

  String? _resolvedMedia(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return null;
    return MediaService.resolveMediaUrl(t);
  }

  Color _trustColor(int value) {
    if (value < 30) return AppTheme.errorColor;
    if (value <= 60) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedMedia(badge.avatarUrl);
    final title = badge.name.trim().isNotEmpty ? badge.name.trim() : 'Tienda';
    final trustC = _trustColor(badge.trustScore);
    final pitch = badge.pitch.trim();

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: resolved != null
                  ? Image.network(
                      resolved,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _PhotoFallback(initial: title),
                    )
                  : _PhotoFallback(initial: title),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (badge.verified)
                _MetaChip(
                  icon: Icons.verified,
                  label: 'Verificada',
                  color: AppTheme.successColor,
                ),
              if (badge.transportIncluded)
                _MetaChip(
                  icon: Icons.local_shipping_outlined,
                  label: 'Transporte incluido',
                  color: AppTheme.primaryColor,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Categorias',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          badge.categories.isEmpty
              ? Text(
                  'Sin categorias en el perfil.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in badge.categories)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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
                ),
          const SizedBox(height: 20),
          Text(
            'Confianza',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Container(
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
                        'Puntuacion de confianza',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${badge.trustScore}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: trustC,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: badge.trustScore.clamp(0, 100) / 100,
                    backgroundColor: AppTheme.surfaceMutedColor,
                    valueColor: AlwaysStoppedAnimation<Color>(trustC),
                  ),
                ),
              ],
            ),
          ),
          if (badge.location != null) ...[
            const SizedBox(height: 20),
            Text(
              'Ubicacion',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      badge.location!.latitude,
                      badge.location!.longitude,
                    ),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.vibetrade.vibe_trade_v1',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            badge.location!.latitude,
                            badge.location!.longitude,
                          ),
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
          ],
          if (pitch.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Descripcion',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.pitch,
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
          if (badge.websiteUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Sitio web',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              badge.websiteUrl,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  final String initial;

  const _PhotoFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    final letter = initial.trim().isNotEmpty ? initial.trim()[0].toUpperCase() : 'T';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.85),
            AppTheme.primaryColor.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: 56,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
