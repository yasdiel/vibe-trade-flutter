import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _buildImage() {
    final path = product.imagePath;
    if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    final letter = product.name.trim().isNotEmpty
        ? product.name.trim()[0].toUpperCase()
        : 'P';
    return Container(
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
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _conditionColor(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.brandNew:
        return AppTheme.successColor;
      case ProductCondition.used:
        return AppTheme.warningColor;
      case ProductCondition.refurbished:
        return AppTheme.isDark
            ? const Color(0xFF60A5FA)
            : const Color(0xFF1D4ED8);
    }
  }

  ProductCurrency? get _displayCurrency =>
      product.priceCurrency ??
      (product.acceptedCurrencies.isNotEmpty
          ? product.acceptedCurrencies.first
          : null);

  String get _formattedPriceValue {
    final price = product.price;
    if (price == price.truncateToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    Color? background,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
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

  Widget _buildPriceBlock() {
    final currency = _displayCurrency;
    final symbol = currency?.symbol ?? '\$';
    final code = currency?.value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
            height: 1,
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            _formattedPriceValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              height: 1.05,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (code != null) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                height: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceCurrency = product.priceCurrency;
    final extraCurrencies = product.acceptedCurrencies
        .where((c) => c != priceCurrency)
        .toList(growable: false);

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
                if (product.category.isNotEmpty)
                  Text(
                    product.category.toUpperCase(),
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
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (product.version.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.version,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _buildPriceBlock(),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    if (product.condition != null)
                      _buildBadge(
                        text: product.condition!.label,
                        color: _conditionColor(product.condition!),
                        icon: Icons.label_important_outline,
                      ),
                    if (product.stock != null)
                      _buildBadge(
                        text: product.stock == 0
                            ? 'Agotado'
                            : '${product.stock} disp.',
                        color: product.stock == 0
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                        icon: product.stock == 0
                            ? Icons.remove_shopping_cart_outlined
                            : Icons.inventory_2_outlined,
                      ),
                    if (extraCurrencies.isNotEmpty)
                      _buildBadge(
                        text: extraCurrencies.length == 1
                            ? '+ ${extraCurrencies.first.value}'
                            : '+${extraCurrencies.length} monedas',
                        color: AppTheme.textSecondary,
                        icon: Icons.currency_exchange,
                      ),
                  ],
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
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
