import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';

class MarketService {
  static String get _catalogCategoriesUrl =>
      '$baseUrl/Market/catalog-categories';

  static Future<List<String>> getCatalogCategories() async {
    final response = await http.get(Uri.parse(_catalogCategoriesUrl));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudieron cargar las categorias: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> rawList = decoded is Map<String, dynamic>
        ? (decoded['categories'] as List<dynamic>? ?? const <dynamic>[])
        : (decoded is List<dynamic> ? decoded : const <dynamic>[]);

    return rawList
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
}
