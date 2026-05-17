import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/catalog/catalog_product_json.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/utils/catalog_id.dart';

/// Catálogo de productos sincronizado con
/// `POST /Market/stores/{id}/detail` y `PUT/DELETE …/products/…`.
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

  /// Sincroniza productos desde `POST …/stores/{storeId}/detail`.
  static Future<void> refreshFromServer(String storeId) async {
    await hydrate();
    final sid = storeId.trim();
    if (sid.isEmpty) return;

    final root = await MarketService.fetchStoreCatalogDetailDecoded(sid);
    final catalog = root['catalog'];
    if (catalog is! Map<String, dynamic>) return;

    final rawList = catalog['products'];
    if (rawList is! List) return;

    final parsed =
        rawList.whereType<Map>().map((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          return CatalogProductJson.fromApiMap(m);
        }).where((p) => p.id.isNotEmpty).toList();

    productsNotifier.value = <ProductModel>[
      ...productsNotifier.value.where((p) => p.storeId != sid),
      ...parsed,
    ];
    await _persist();
    await _syncStoreCount(sid);
  }

  static Future<ProductModel> createProductViaApi({
    required String storeId,
    required String name,
    required String category,
    required String version,
    required double price,
    required ProductCurrency priceCurrency,
    required ProductCondition condition,
    required List<ProductCurrency> acceptedCurrencies,
    required String description,
    required String mainBenefit,
    required String technicalFeatures,
    File? pendingImageFile,
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

    if (pendingImageFile == null) {
      throw StateError('Se requiere al menos una foto del producto.');
    }

    final productId = generateCatalogId('prd');
    var draft = ProductModel(
      id: productId,
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
      imagePath: '',
      photoUrls: const <String>[],
      createdAt: DateTime.now(),
      taxesShippingInstall: taxesShippingInstall.trim(),
      stock: stock,
      warrantyAndReturns: warrantyAndReturns.trim(),
      includedContent: includedContent.trim(),
      usageConditions: usageConditions.trim(),
      published: false,
    );

    final url = await MediaService.uploadAvatar(pendingImageFile);
    final urls = [url];
    draft = draft.copyWith(imagePath: url, photoUrls: urls);

    final body = CatalogProductJson.toUpsertBody(
      draft,
      storeId: storeId,
      photoUrls: urls,
      published: false,
    );

    await MarketService.putStoreProduct(
      storeId: storeId,
      productId: productId,
      body: body,
    );
    await refreshFromServer(storeId);
    return getById(productId) ?? draft;
  }

  static Future<ProductModel> updateProductViaApi(
    String id, {
    required String storeId,
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
    File? pendingImageFile,
    Object? stock = _kStockUnset,
    String? taxesShippingInstall,
    String? warrantyAndReturns,
    String? includedContent,
    String? usageConditions,
  }) async {
    await hydrate();
    final existing = getById(id);
    if (existing == null) throw StateError('Producto no encontrado');

    List<ProductCurrency>? normalizedCurrencies;
    if (acceptedCurrencies != null || priceCurrency != null) {
      final base = acceptedCurrencies ?? existing.acceptedCurrencies;
      final pc = priceCurrency ?? existing.priceCurrency;
      normalizedCurrencies = <ProductCurrency>{
        if (pc != null) pc,
        ...base,
      }.toList(growable: false);
    }

    var next = existing.copyWith(
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
      taxesShippingInstall: taxesShippingInstall?.trim(),
      stock:
          identical(stock, _kStockUnset) ? existing.stock : stock as int?,
      warrantyAndReturns: warrantyAndReturns?.trim(),
      includedContent: includedContent?.trim(),
      usageConditions: usageConditions?.trim(),
    );

    File? uploadCandidate = pendingImageFile;
    if (uploadCandidate == null &&
        next.imagePath.isNotEmpty &&
        _looksLikeLocalFilesystemPath(next.imagePath)) {
      try {
        final f = File(next.imagePath.trim());
        if (f.existsSync()) uploadCandidate = f;
      } catch (_) {}
    }

    var photoUrls = _resolveProductPhotoUrls(next);
    if (uploadCandidate != null) {
      final u = await MediaService.uploadAvatar(uploadCandidate);
      photoUrls = [u];
      next = next.copyWith(imagePath: u, photoUrls: photoUrls);
    }

    if (photoUrls.isEmpty) {
      throw StateError('Se requiere al menos una foto del producto.');
    }

    final body = CatalogProductJson.toUpsertBody(
      next,
      storeId: storeId,
      photoUrls: photoUrls,
      published: existing.published,
    );

    await MarketService.putStoreProduct(
      storeId: storeId,
      productId: id,
      body: body,
    );
    await refreshFromServer(storeId);
    return getById(id) ?? next;
  }

  static Future<ProductModel> publishProduct(
    String storeId,
    String productId,
  ) async {
    await hydrate();
    final existing = getById(productId);
    if (existing == null || existing.storeId != storeId) {
      throw StateError('Producto no encontrado');
    }
    final photoUrls = _resolveProductPhotoUrls(existing);
    if (photoUrls.isEmpty) {
      throw StateError(
        'No se puede publicar un producto sin imagen en la ficha.',
      );
    }
    final body = CatalogProductJson.toUpsertBody(
      existing,
      storeId: storeId,
      photoUrls: photoUrls,
      published: true,
    );
    await MarketService.putStoreProduct(
      storeId: storeId,
      productId: productId,
      body: body,
    );
    await refreshFromServer(storeId);
    return getById(productId) ?? existing.copyWith(published: true);
  }

  static Future<void> deleteProduct(String id) async {
    await hydrate();
    final removed = getById(id);
    final sid = removed?.storeId.trim() ?? '';
    if (removed != null && sid.isNotEmpty) {
      await MarketService.deleteStoreProduct(storeId: sid, productId: id);
      await refreshFromServer(sid);
    } else {
      productsNotifier.value = productsNotifier.value
          .where((product) => product.id != id)
          .toList(growable: false);
      await _persist();
    }

    if (removed != null && removed.storeId.isNotEmpty) {
      await _syncStoreCount(removed.storeId);
    }
  }

  static Future<void> deleteAllForStore(String storeId) async {
    await hydrate();
    final ours =
        productsNotifier.value
            .where((p) => p.storeId == storeId)
            .toList();
    for (final p in ours) {
      try {
        await MarketService.deleteStoreProduct(
          storeId: storeId,
          productId: p.id,
        );
      } catch (_) {
        debugPrint('[ProductService] deleteAll omitido ${p.id}');
      }
    }
    productsNotifier.value =
        productsNotifier.value
            .where((product) => product.storeId != storeId)
            .toList(growable: false);
    await _persist();
    await _syncStoreCount(storeId);
  }

  static bool _looksLikeLocalFilesystemPath(String path) {
    final t = path.trim();
    if (t.isEmpty ||
        t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.startsWith('/api/')) {
      return false;
    }
    return true;
  }

  static Future<void> _syncStoreCount(String storeId) async {
    final count =
        productsNotifier.value.where((p) => p.storeId == storeId).length;
    if (StoreService.getById(storeId) == null) return;
    try {
      await StoreService.updateStore(storeId, productsCount: count);
    } catch (_) {}
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

  static List<String> _resolveProductPhotoUrls(ProductModel p) {
    final fromList =
        p.photoUrls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
    if (fromList.isNotEmpty) {
      return fromList
          .where((u) => isCatalogMediaUrl(u) || File(u).existsSync())
          .toList(growable: false);
    }
    final single = p.imagePath.trim();
    if (single.isEmpty) return const <String>[];
    if (isCatalogMediaUrl(single) || File(single).existsSync()) {
      return [single];
    }
    return const <String>[];
  }
}

const Object _kStockUnset = Object();
