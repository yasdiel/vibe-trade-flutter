import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/services/store_service.dart';

/// Mock catalog of products. Each product belongs to a store via [storeId].
/// Persists to [SharedPreferences] and keeps the parent store's
/// [StoreModel.productsCount] in sync automatically.
class ProductService {
  static const String _productsKey = 'simulated_products';

  static final ValueNotifier<List<ProductModel>> productsNotifier =
      ValueNotifier<List<ProductModel>>(<ProductModel>[]);

  static bool _hydrated = false;

  static Future<void> hydrate() async {
    if (_hydrated) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_productsKey);
    productsNotifier.value = _decode(raw);
    _hydrated = true;
  }

  static List<ProductModel> productsForStore(String storeId) {
    return productsNotifier.value
        .where((product) => product.storeId == storeId)
        .toList(growable: false);
  }

  static ProductModel? getById(String id) {
    for (final product in productsNotifier.value) {
      if (product.id == id) return product;
    }
    return null;
  }

  static Future<ProductModel> createProduct({
    required String storeId,
    required String name,
    required String category,
    required String version,
    required double price,
    required ProductCurrency priceCurrency,
    required ProductCondition condition,
    required List<ProductCurrency> acceptedCurrencies,
    String description = '',
    String mainBenefit = '',
    String technicalFeatures = '',
    String imagePath = '',
    String taxesShippingInstall = '',
    int? stock,
    String warrantyAndReturns = '',
    String includedContent = '',
    String usageConditions = '',
  }) async {
    await hydrate();
    final normalizedCurrencies = <ProductCurrency>{
      priceCurrency,
      ...acceptedCurrencies,
    }.toList(growable: false);
    final product = ProductModel(
      id: _generateId(),
      storeId: storeId,
      name: name.trim(),
      category: category.trim(),
      version: version.trim(),
      price: price,
      priceCurrency: priceCurrency,
      condition: condition,
      acceptedCurrencies: List<ProductCurrency>.unmodifiable(
        normalizedCurrencies,
      ),
      description: description.trim(),
      mainBenefit: mainBenefit.trim(),
      technicalFeatures: technicalFeatures.trim(),
      imagePath: imagePath,
      createdAt: DateTime.now(),
      taxesShippingInstall: taxesShippingInstall.trim(),
      stock: stock,
      warrantyAndReturns: warrantyAndReturns.trim(),
      includedContent: includedContent.trim(),
      usageConditions: usageConditions.trim(),
    );
    productsNotifier.value = <ProductModel>[
      ...productsNotifier.value,
      product,
    ];
    await _persist();
    await _syncStoreCount(storeId);
    return product;
  }

  static Future<ProductModel> updateProduct(
    String id, {
    String? name,
    String? category,
    String? version,
    double? price,
    ProductCurrency? priceCurrency,
    ProductCondition? condition,
    List<ProductCurrency>? acceptedCurrencies,
    String? description,
    String? mainBenefit,
    String? technicalFeatures,
    String? imagePath,
    String? taxesShippingInstall,
    Object? stock = _kStockUnset,
    String? warrantyAndReturns,
    String? includedContent,
    String? usageConditions,
  }) async {
    await hydrate();
    final list = <ProductModel>[...productsNotifier.value];
    final index = list.indexWhere((product) => product.id == id);
    if (index == -1) {
      throw StateError('Producto no encontrado');
    }

    List<ProductCurrency>? normalizedCurrencies;
    if (acceptedCurrencies != null || priceCurrency != null) {
      final base = acceptedCurrencies ?? list[index].acceptedCurrencies;
      final pc = priceCurrency ?? list[index].priceCurrency;
      final merged = <ProductCurrency>{
        if (pc != null) pc,
        ...base,
      };
      normalizedCurrencies = merged.toList(growable: false);
    }

    final updated = list[index].copyWith(
      name: name?.trim(),
      category: category?.trim(),
      version: version?.trim(),
      price: price,
      priceCurrency: priceCurrency,
      condition: condition,
      acceptedCurrencies: normalizedCurrencies,
      description: description?.trim(),
      mainBenefit: mainBenefit?.trim(),
      technicalFeatures: technicalFeatures?.trim(),
      imagePath: imagePath,
      taxesShippingInstall: taxesShippingInstall?.trim(),
      stock: identical(stock, _kStockUnset) ? list[index].stock : stock,
      warrantyAndReturns: warrantyAndReturns?.trim(),
      includedContent: includedContent?.trim(),
      usageConditions: usageConditions?.trim(),
    );
    list[index] = updated;
    productsNotifier.value = list;
    await _persist();
    return updated;
  }

  static Future<void> deleteProduct(String id) async {
    await hydrate();
    final removed = getById(id);
    productsNotifier.value = productsNotifier.value
        .where((product) => product.id != id)
        .toList(growable: false);
    await _persist();
    if (removed != null) {
      await _syncStoreCount(removed.storeId);
    }
  }

  static Future<void> deleteAllForStore(String storeId) async {
    await hydrate();
    productsNotifier.value = productsNotifier.value
        .where((product) => product.storeId != storeId)
        .toList(growable: false);
    await _persist();
    await _syncStoreCount(storeId);
  }

  static Future<void> _syncStoreCount(String storeId) async {
    final count = productsNotifier.value
        .where((product) => product.storeId == storeId)
        .length;
    if (StoreService.getById(storeId) == null) return;
    try {
      await StoreService.updateStore(storeId, productsCount: count);
    } catch (_) {
      // Si la tienda fue eliminada en paralelo, no propagamos el error.
    }
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      productsNotifier.value.map((product) => product.toJson()).toList(),
    );
    await prefs.setString(_productsKey, encoded);
  }

  static List<ProductModel> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <ProductModel>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <ProductModel>[];
      return decoded
          .whereType<Map>()
          .map((map) => ProductModel.fromJson(Map<String, dynamic>.from(map)))
          .toList(growable: false);
    } catch (_) {
      return const <ProductModel>[];
    }
  }

  static String _generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = Random().nextInt(0xFFFF);
    return '$timestamp-${random.toRadixString(16)}';
  }
}

const Object _kStockUnset = Object();
