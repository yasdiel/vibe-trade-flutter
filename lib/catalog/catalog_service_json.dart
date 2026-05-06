import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/models/service_model.dart';

bool _publishedFromApi(dynamic v) {
  if (v == true) return true;
  if (v == false) return false;
  return true;
}

List<ProductCurrency> _monedas(dynamic raw) {
  if (raw is! List) return const <ProductCurrency>[];
  final out = <ProductCurrency>[];
  for (final e in raw.whereType<String>()) {
    final c = ProductCurrency.fromValue(e.trim());
    if (c != null) out.add(c);
  }
  return List<ProductCurrency>.unmodifiable(out);
}

String _itemsBlockText(dynamic node) {
  if (node is! Map || node['enabled'] != true) return '';
  final items = node['items'];
  if (items is! List) return '';
  final buf = StringBuffer();
  for (final it in items) {
    if (it is Map) {
      final row = Map<String, dynamic>.from(it as Map);
      final t =
          (row['detail'] ??
                  row['text'] ??
                  row['detalle'] ??
                  '')
              .toString()
              .trim();
      if (t.isNotEmpty) {
        if (buf.isNotEmpty) buf.writeln();
        buf.write(t);
      }
    }
  }
  return buf.toString().trim();
}

String _warrantyText(dynamic node) {
  if (node is! Map || node['enabled'] != true) return '';
  return node['texto']?.toString().trim() ?? '';
}

/// Mapeo con el JSON de servicios del backend (`ServiceToJson` / PUT).
class CatalogServiceJson {
  const CatalogServiceJson._();

  static ServiceModel fromApiMap(Map<String, dynamic> map) {
    final mon = _monedas(map['monedas']);

    final riesgosRaw = map['riesgos'];
    final depRaw = map['dependencias'];
    final garRaw = map['garantias'];

    final rText = _itemsBlockText(riesgosRaw);
    final dText = _itemsBlockText(depRaw);
    final garText = _warrantyText(garRaw);

    final photoUrlsRaw = map['photoUrls'];
    final images = <String>[];
    if (photoUrlsRaw is List) {
      for (final x in photoUrlsRaw) {
        final s = x?.toString().trim() ?? '';
        if (s.isNotEmpty) images.add(s);
      }
    }

    return ServiceModel(
      id: map['id']?.toString().trim() ?? '',
      storeId: map['storeId']?.toString().trim() ?? '',
      category: map['category']?.toString() ?? '',
      serviceType: map['tipoServicio']?.toString() ?? '',
      acceptedCurrencies: mon,
      description: map['descripcion']?.toString() ?? '',
      hasRisks: rText.isNotEmpty,
      risks: rText,
      includes: map['incluye']?.toString() ?? '',
      excludes: map['noIncluye']?.toString() ?? '',
      hasDependencies: dText.isNotEmpty,
      dependencies: dText,
      delivery: map['entregables']?.toString() ?? '',
      hasWarranty: garText.isNotEmpty,
      warranty: garText,
      intellectualProperty: map['propIntelectual']?.toString() ?? '',
      imagePaths:
          images.isEmpty
              ? const <String>[]
              : List<String>.unmodifiable(images),
      createdAt: DateTime.now(),
      published: _publishedFromApi(map['published']),
    );
  }

  static Map<String, dynamic> toUpsertBody(
    ServiceModel s, {
    required bool published,
  }) =>
      <String, dynamic>{
        'id': s.id,
        'storeId': s.storeId,
        'category': s.category.trim(),
        'tipoServicio': s.serviceType.trim(),
        'descripcion': s.description.trim(),
        'incluye': s.includes.trim(),
        'noIncluye': s.excludes.trim(),
        'entregables': s.delivery.trim(),
        'propIntelectual': s.intellectualProperty.trim(),
        'monedas': s.acceptedCurrencies.map((e) => e.value).toList(),
        'published': published,
        'riesgos': {
          'enabled': s.hasRisks && s.risks.trim().isNotEmpty,
          'items':
              (s.hasRisks && s.risks.trim().isNotEmpty)
                  ? <Map<String, String>>[
                    {'detail': s.risks.trim()},
                  ]
                  : <Map<String, String>>[],
        },
        'dependencias': {
          'enabled': s.hasDependencies && s.dependencies.trim().isNotEmpty,
          'items':
              (s.hasDependencies && s.dependencies.trim().isNotEmpty)
                  ? <Map<String, String>>[
                    {'detail': s.dependencies.trim()},
                  ]
                  : <Map<String, String>>[],
        },
        'garantias': {
          'enabled': s.hasWarranty && s.warranty.trim().isNotEmpty,
          'texto': s.hasWarranty ? s.warranty.trim() : '',
        },
        'photoUrls': s.imagePaths,
        'customFields': <dynamic>[],
      };
}
