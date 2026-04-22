import 'dart:convert';

import '../models/country_model.dart';
import 'package:http/http.dart' as http;

class CountryServices {
  static Future<List<CountryModel>> getCountries() async {
    final response = await http.get(Uri.parse('/'));
    final List data = jsonDecode(response.body);
    return data.map((e) => CountryModel.fromJson(e)).toList();
  }
}
