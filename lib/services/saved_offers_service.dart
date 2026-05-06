import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

/// POST/DELETE `…/me/saved-offers`. Lista inicial desde `GET …/Bootstrap` (`savedOfferIds`).
class SavedOffersService {
  static final ValueNotifier<Set<String>> idsNotifier =
      ValueNotifier<Set<String>>({});

  static String get _baseUrl => '$baseUrl/me/saved-offers';

  static String get _bootstrapUrl => '$baseUrl/Bootstrap';

  static void clear() {
    idsNotifier.value = <String>{};
  }

  static Set<String> get currentIds =>
      Set<String>.unmodifiable(idsNotifier.value);

  static List<String> _parseIdsResponse(http.Response response) {
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    final raw = decoded['savedOfferIds'];
    if (raw is! List) return [];
    return raw.whereType<String>().toList(growable: false);
  }

  /// Carga `savedOfferIds` desde el bootstrap autenticado (sin endpoint extra en `/me`).
  static Future<void> hydrateFromServer() async {
    final token = await SessionService.getSavedToken();
    if (token == null) {
      clear();
      return;
    }

    final response = await http.get(
      Uri.parse(_bootstrapUrl),
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback:
              'No se pudo cargar el bootstrap (${response.statusCode}).',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      idsNotifier.value = {};
      return;
    }
    final raw = decoded['savedOfferIds'];
    if (raw is! List) {
      idsNotifier.value = {};
      return;
    }
    idsNotifier.value = raw.whereType<String>().toSet();
  }

  static Future<void> saveOffer(String offerId) async {
    await _mutateOffer(offerId, post: true);
  }

  static Future<void> removeOffer(String offerId) async {
    await _mutateOffer(offerId, post: false);
  }

  static Future<void> _mutateOffer(String offerId, {required bool post}) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final uri = post
        ? Uri.parse(_baseUrl)
        : Uri.parse(
            '$_baseUrl/${Uri.encodeComponent(offerId)}',
          );
    final response = post
        ? await http.post(
            uri,
            headers: {
              'Authorization': SessionService.buildAuthorizationHeader(token),
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'productId': offerId}),
          )
        : await http.delete(
            uri,
            headers: {
              'Authorization': SessionService.buildAuthorizationHeader(token),
              'Accept': 'application/json',
            },
          );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo actualizar la oferta guardada.',
        ),
      );
    }

    idsNotifier.value = _parseIdsResponse(response).toSet();
  }
}
