import 'dart:math';

/// Ids de catálogo alineados con el demo web (`prd_…`, `svc_…`).
String generateCatalogId(String prefix) {
  final p = prefix.trim();
  if (p.isEmpty) {
    throw ArgumentError('prefix vacío');
  }
  final hex = Random().nextInt(0xFFFFFFFF).toRadixString(16);
  return '${p}_${hex}_${DateTime.now().millisecondsSinceEpoch}';
}

bool isCatalogMediaUrl(String path) {
  final t = path.trim();
  return t.startsWith('/api/v1/media/') ||
      t.startsWith('api/v1/media/') ||
      t.startsWith('http://') ||
      t.startsWith('https://');
}
