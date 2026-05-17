import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_image_placeholder.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_website_link.dart';

/// Tiendas recomendadas: orden derivado del ranking actual de `offerIds` (+ `storeBadges`).
/// Los badges siguen [`MarketCatalogStoreBadgeJson`] del backend (.NET).
class HomeRecommendedStoresList extends StatelessWidget {
  final List<String> storeIds;
  final Map<String, StoreBadgeModel> badges;
  final void Function(String storeId) onStoreTap;

  const HomeRecommendedStoresList({
    super.key,
    required this.storeIds,
    required this.badges,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = storeIds.where((id) => badges[id] != null).toList();
    if (items.isEmpty) {
      return Text(
        'No hay tiendas destacadas por ahora.',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _RecommendedStoreTile(
            badge: badges[items[i]]!,
            onTap: () => onStoreTap(items[i]),
          ),
        ],
      ],
    );
  }
}

Color _trustColor(int value) {
  if (value < 30) return AppTheme.errorColor;
  if (value <= 60) return AppTheme.warningColor;
  return AppTheme.successColor;
}

class _HomeRecommendedTrustBar extends StatelessWidget {
  final int score;
  final Color color;

  const _HomeRecommendedTrustBar({
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final v = score.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Confianza',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Text(
              '$v%',
              style: TextStyle(
                fontSize: 12,
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
            minHeight: 6,
            value: v / 100,
            backgroundColor: AppTheme.surfaceMutedColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RecommendedStoreTile extends StatelessWidget {
  final StoreBadgeModel badge;
  final VoidCallback onTap;

  const _RecommendedStoreTile({
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trustC = _trustColor(badge.trustScore);

    return Material(
      color: AppTheme.subtleSurfaceColor,
      elevation: AppTheme.isDark ? 6 : 2,
      shadowColor:
          Colors.black.withValues(alpha: AppTheme.isDark ? 0.42 : 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StoreAvatar(badge: badge),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            badge.name.trim().isNotEmpty ? badge.name : 'Tienda',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (badge.verified)
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
                    const SizedBox(height: 8),
                    _HomeRecommendedTrustBar(
                      score: badge.trustScore,
                      color: trustC,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (badge.transportIncluded)
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        if (badge.location != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 15,
                                color: AppTheme.textSecondary,
                              ),
                              Text(
                                ' Ubicacion',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (badge.categories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in badge.categories)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.selectedColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                c,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if (badge.pitch.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        badge.pitch,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (badge.websiteUrl.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      StoreWebsiteLink(
                        url: badge.websiteUrl,
                        maxLines: 1,
                        fontSize: 11,
                        showIcon: true,
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

class _StoreAvatar extends StatelessWidget {
  final StoreBadgeModel badge;

  const _StoreAvatar({required this.badge});

  @override
  Widget build(BuildContext context) {
    final raw = badge.avatarUrl?.trim();
    final url =
        raw != null && raw.isNotEmpty ? MediaService.resolveMediaUrl(raw) : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: url != null
            ? Image.network(
                url,
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
    return const StoreImagePlaceholder(
      width: 44,
      height: 44,
      iconSize: 22,
      borderRadius: BorderRadius.zero,
    );
  }
}

void showRecommendedStoresBottomSheet({
  required BuildContext context,
  required List<String> storeIds,
  required Map<String, StoreBadgeModel> badges,
  required void Function(String storeId) onStoreTap,
}) {
  final maxH = MediaQuery.sizeOf(context).height * 0.72;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: MediaQuery.paddingOf(ctx).bottom + 12,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.foregroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: SizedBox(
          height: maxH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
                child: Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Tiendas recomendadas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.dividerColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: HomeRecommendedStoresList(
                        storeIds: storeIds,
                        badges: badges,
                        onStoreTap: (id) {
                          Navigator.pop(ctx);
                          onStoreTap(id);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
