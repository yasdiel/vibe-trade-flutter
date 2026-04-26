import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';

import '../models/country_model.dart';

class CountryServices {
  static String get _countriesUrl => '$baseUrl/Auth/sign-in-countries';

  static Future<List<CountryModel>> getCountries() async {
    final response = await http.get(Uri.parse(_countriesUrl));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load countries: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
          (country) => CountryModel.fromJson(country as Map<String, dynamic>),
        )
        .toList();
  }
}
