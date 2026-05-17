import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/service_model.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/serviceConfiguration/service_image_placeholder.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onPublish;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onEdit,
    required this.onDelete,
    this.onPublish,
  });

  String? _firstDisplayPath() {
    for (final path in service.imagePaths) {
      final t = path.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('http://') ||
          t.startsWith('https://') ||
          t.startsWith('/api/')) {
        return t;
      }
      if (File(t).existsSync()) {
        return t;
      }
    }
    return null;
  }

  Widget _fallbackPlaceholder() {
    return const ServiceImagePlaceholder(iconSize: 40);
  }

  Widget _galleryBadge() {
    if (service.imagePaths.length <= 1) return const SizedBox.shrink();
    return Positioned(
      right: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '${service.imagePaths.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final path = _firstDisplayPath();

    if (path != null &&
        (path.startsWith('http://') ||
            path.startsWith('https://') ||
            path.startsWith('/api/'))) {
      final url = MediaService.resolveMediaUrl(path);
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackPlaceholder(),
          ),
          _galleryBadge(),
        ],
      );
    }
    if (path != null && File(path).existsSync()) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(path), fit: BoxFit.cover),
          _galleryBadge(),
        ],
      );
    }

    return _fallbackPlaceholder();
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: _buildImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.category.isNotEmpty)
                  Text(
                    service.category.toUpperCase(),
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
                  service.serviceType.isNotEmpty
                      ? service.serviceType
                      : 'Servicio sin nombre',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    if (!service.published)
                      _buildBadge(
                        text: 'Borrador',
                        color: AppTheme.warningColor,
                        icon: Icons.visibility_off_outlined,
                      ),
                    if (service.hasWarranty)
                      _buildBadge(
                        text: 'Garantia',
                        color: AppTheme.successColor,
                        icon: Icons.verified_user_outlined,
                      ),
                    if (service.hasRisks)
                      _buildBadge(
                        text: 'Riesgos',
                        color: AppTheme.warningColor,
                        icon: Icons.warning_amber_outlined,
                      ),
                    if (service.hasDependencies)
                      _buildBadge(
                        text: 'Dependencias',
                        color: AppTheme.textSecondary,
                        icon: Icons.account_tree_outlined,
                      ),
                    if (service.acceptedCurrencies.isNotEmpty)
                      _buildBadge(
                        text: service.acceptedCurrencies
                            .map((c) => c.value)
                            .join(' / '),
                        color: AppTheme.primaryColor,
                        icon: Icons.payments_outlined,
                      ),
                  ],
                ),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    service.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                if (!service.published && onPublish != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: onPublish,
                      icon: const Icon(Icons.publish, size: 16),
                      label: const Text(
                        'Publicar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text(
                          'Editar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 38,
                      height: 34,
                      child: OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: BorderSide(color: AppTheme.errorColor),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.delete_outline, size: 16),
                      ),
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
