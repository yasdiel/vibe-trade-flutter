import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/recommendations_response.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/guest_id_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

class RecommendationsService {
  /// Cliente del controlador `Recommendations` (`api/v1/Recommendations`).
  ///
  /// **Autenticado**: Bootstrap en [HomeRecommendationsLoader] solo para guardados /
  /// reserva; **la grilla** usa sobre todo `GET …/Recommendations?take=` (~[defaultTake]).
  ///
  /// **Invitado**: `GET …/guest?guestId=&take=` sin JWT; `guestId` ≥ 8 (persistido con
  /// [GuestIdService]). El JSON es el mismo: `offerIds` + `offers` + `storeBadges`; los
  /// likes se enriquecen en servidor con clave `u:…` vs `g:…`.
  static String get _recommendationsUrl => '$baseUrl/Recommendations';

  /// `GET {baseUrl}/Recommendations/guest?guestId=&take=` — sin cuenta.
  static String get _recommendationsGuestUrl => '$baseUrl/Recommendations/guest';

  /// Omisión servidor `RecommendationService.DefaultBatchSize`; el cliente puede
  /// pedir un `take` mayor (p. ej. `DefaultBootstrapTake` 140).
  static const int defaultTake = 140;

  static Map<String, dynamic> _rootMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      final out = <String, dynamic>{};
      decoded.forEach((k, v) {
        out[k.toString()] = v;
      });
      return out;
    }
    throw Exception(
      'Las recomendaciones no son un objeto JSON (tipo: ${decoded.runtimeType}).',
    );
  }

  /// Sin cursores en la API actual.
  ///
  /// - Con token persistido: `GET …/Recommendations?take=` con `Authorization`.
  /// - Sin token (usuario no autenticado): `GET …/Recommendations/guest?guestId=&take=`.
  ///
  /// Si [logResponseBody] y la app está en modo debug (`kDebugMode`),
  /// imprime URL, modo (authenticated / guest), status y **cuerpo** de la respuesta
  /// en consola (paridad con los logs `[Bootstrap]` de `BootstrapRootService`).
  static Future<RecommendationsResponse> fetchRecommendations({
    int take = defaultTake,
    bool logResponseBody = false,
  }) async {
    final token = (await SessionService.getSavedToken())?.trim();
    // Invitado solo cuando no hay token (paridad con BootstrapRootService.fetchRootJson).
    final useAuthFeed = token != null && token.isNotEmpty;

    final boundedTake = take.clamp(1, 500);

    final Uri uri;
    final Map<String, String> headers = {'Accept': 'application/json'};

    if (useAuthFeed) {
      uri = Uri.parse(_recommendationsUrl).replace(
        queryParameters: <String, String>{'take': '$boundedTake'},
      );
      headers['Authorization'] =
          SessionService.buildAuthorizationHeader(token);
    } else {
      final guestId = await GuestIdService.getOrCreate();
      uri = Uri.parse(_recommendationsGuestUrl).replace(
        queryParameters: <String, String>{
          'guestId': guestId,
          'take': '$boundedTake',
        },
      );
    }

    final response = await http.get(uri, headers: headers);

    if (kDebugMode && logResponseBody) {
      final mode = useAuthFeed ? 'authenticated' : 'guest';
      debugPrint(
        '[Recommendations] GET $mode ${uri.scheme}://${uri.host}${uri.path}'
        '${uri.hasQuery ? '?${uri.query}' : ''} '
        'status=${response.statusCode}',
      );
      debugPrint('[Recommendations] response body:\n${response.body}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (useAuthFeed) {
        await SessionService.handleUnauthorized();
      }
      throw const UnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback:
              'No se pudieron cargar las recomendaciones (status ${response.statusCode}).',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    return RecommendationsResponse.fromJson(_rootMap(decoded));
  }

  /// Registra clic u otra interacción para el ranking del feed.
  static Future<void> postInteraction({
    required String offerId,
    required String eventType,
  }) async {
    final token = (await SessionService.getSavedToken())?.trim();
    final useAuthInteraction = token != null && token.isNotEmpty;

    if (useAuthInteraction) {
      final response = await http.post(
        Uri.parse('$_recommendationsUrl/interactions'),
        headers: {
          'Authorization': SessionService.buildAuthorizationHeader(token),
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'offerId': offerId.trim(),
          'eventType': eventType.trim(),
        }),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await SessionService.handleUnauthorized();
      }
      return;
    }

    final guestId = await GuestIdService.getOrCreate();
    await http.post(
      Uri.parse('$_recommendationsUrl/guest/interactions'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'guestId': guestId,
        'offerId': offerId.trim(),
        'eventType': eventType.trim(),
      }),
    );
  }
}
