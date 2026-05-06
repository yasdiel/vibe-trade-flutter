import 'package:vibe_trade_v1/models/product_model.dart';

double _parsePrice(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  final s = v.toString().trim().replaceAll(',', '.');
  return double.tryParse(s) ?? 0;
}

int? _parseStockFromAvailability(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final parsed = int.tryParse(t);
  if (parsed != null) return parsed;
  final m = RegExp(r'(?:stock|cantidad)\s*[:\s]?\s*(\d+)', caseSensitive: false)
      .firstMatch(t);
  if (m != null) return int.tryParse(m.group(1)!);
  return null;
}

List<ProductCurrency> _parseMonedas(dynamic raw) {
  if (raw is! List) return const <ProductCurrency>[];
  final out = <ProductCurrency>[];
  for (final e in raw.whereType<String>()) {
    final c = ProductCurrency.fromValue(e.trim());
    if (c != null) out.add(c);
  }
  return List<ProductCurrency>.unmodifiable(out);
}

/// Mapeo entre [ProductModel] y el JSON del Market (ProductToJson / PUT).
class CatalogProductJson {
  const CatalogProductJson._();

  static ProductModel fromApiMap(Map<String, dynamic> map) {
    final monedas = _parseMonedas(map['monedas']);
    final monedaPrecioStr = map['monedaPrecio'] as String?;
    final pc = ProductCurrency.fromValue((monedaPrecioStr ?? '').trim());
    final currencies =
        pc != null
            ? (monedas.contains(pc) ? monedas : [...monedas, pc]).toSet().toList()
            : List<ProductCurrency>.from(monedas);

    final price = _parsePrice(map['price']);
    final avail = map['availability']?.toString() ?? '';

    final urlsRaw = map['photoUrls'];
    final urlsList = urlsRaw is List
        ? urlsRaw
              .whereType<Object>()
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList()
        : const <String>[];
    final imagePath =
        urlsList.isNotEmpty ? urlsList.first : '';

    final condRaw = map['condition']?.toString().trim() ?? '';
    final condition = ProductCondition.fromValue(condRaw);

    return ProductModel(
      id: (map['id'] as String?)?.trim() ?? '',
      storeId: (map['storeId'] as String?)?.trim() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      version: map['model']?.toString() ?? '',
      price: price,
      priceCurrency: pc ?? (currencies.isNotEmpty ? currencies.first : null),
      condition: condition,
      acceptedCurrencies: List<ProductCurrency>.unmodifiable(currencies),
      description: map['shortDescription']?.toString() ?? '',
      mainBenefit: map['mainBenefit']?.toString() ?? '',
      technicalFeatures: map['technicalSpecs']?.toString() ?? '',
      imagePath: imagePath,
      photoUrls: List<String>.unmodifiable(urlsList),
      createdAt: DateTime.now(),
      taxesShippingInstall: map['taxesShippingInstall']?.toString() ?? '',
      stock: _parseStockFromAvailability(avail),
      warrantyAndReturns: map['warrantyReturn']?.toString() ?? '',
      includedContent: map['contentIncluded']?.toString() ?? '',
      usageConditions: map['usageConditions']?.toString() ?? '',
      published: map['published'] == true,
    );
  }

  static Map<String, dynamic> toUpsertBody(
    ProductModel p, {
    required String storeId,
    List<String>? photoUrls,
    required bool published,
  }) {
    final pc = p.priceCurrency;
    final monedaPrecio = pc?.value ?? '';

    final urlsResolved =
        photoUrls ??
        () {
          if (p.photoUrls.isNotEmpty) return p.photoUrls.toList(growable: false);
          if (p.imagePath.trim().isNotEmpty) return [p.imagePath.trim()];
          return const <String>[];
        }();

    final availability = p.stock == null
        ? ''
        : (p.stock == 0 ? 'Agotado' : 'Stock: ${p.stock}');

    return <String, dynamic>{
      'id': p.id,
      'storeId': storeId,
      'category': p.category.trim(),
      'name': p.name.trim(),
      'model': p.version.trim(),
      'shortDescription': p.description.trim(),
      'mainBenefit': p.mainBenefit.trim(),
      'technicalSpecs': p.technicalFeatures.trim(),
      'condition': p.condition?.value ?? '',
      'price': p.price.toString(),
      'monedaPrecio': monedaPrecio,
      'monedas':
          (p.acceptedCurrencies.map((e) => e.value).toList()),
      if (p.taxesShippingInstall.trim().isNotEmpty)
        'taxesShippingInstall': p.taxesShippingInstall.trim(),
      'availability': availability,
      'warrantyReturn': p.warrantyAndReturns.trim(),
      'contentIncluded': p.includedContent.trim(),
      'usageConditions': p.usageConditions.trim(),
      'published': published,
      'photoUrls': urlsResolved,
      'customFields': <dynamic>[],
    };
  }
}
