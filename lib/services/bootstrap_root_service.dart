import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/services/guest_id_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

/// JSON raíz de `BootstrapResponseDto` como en `bootstrapWebApp.ts` del cliente web.
class BootstrapRootService {
  BootstrapRootService._();

  static String get _authUrl => '$baseUrl/Bootstrap';

  /// Ruta fija `bootstrap/guest` (controlador de invitados del API).
  static String get _guestUrl => '$baseUrl/bootstrap/guest';

  /// `GET …/Bootstrap` con JWT si hay token persistido; si no hay sesión,
  /// **`GET …/bootstrap/guest?guestId=`** (solo usuario no autenticado).
  ///
  /// Devuelve `null` ante error HTTP o cuerpo no objeto (el caller puede usar sólo Recommendations).
  ///
  /// Si [logResponseBody] es true **y** la app está en modo debug (`kDebugMode`),
  /// escribe URL, modo (authenticated / guest) y el cuerpo HTTP en consola.
  static Future<Map<String, dynamic>?> fetchRootJson({
    bool logResponseBody = false,
  }) async {
    final token = (await SessionService.getSavedToken())?.trim();
    final useAuth = token != null && token.isNotEmpty;

    final Uri uri;
    final headers = <String, String>{'Accept': 'application/json'};

    if (useAuth) {
      uri = Uri.parse(_authUrl);
      headers['Authorization'] =
          SessionService.buildAuthorizationHeader(token);
    } else {
      uri = Uri.parse(_guestUrl).replace(
        queryParameters: {'guestId': await GuestIdService.getOrCreate()},
      );
    }

    http.Response response;
    try {
      response = await http.get(uri, headers: headers);
    } catch (e, st) {
      if (kDebugMode && logResponseBody) {
        debugPrint(
          '[Bootstrap] GET fallo de red useAuth=$useAuth uri=$uri error=$e\n$st',
        );
      }
      return null;
    }

    if (kDebugMode && logResponseBody) {
      final mode = useAuth ? 'authenticated' : 'guest';
      debugPrint(
        '[Bootstrap] GET $mode ${uri.scheme}://${uri.host}${uri.path}'
        '${uri.hasQuery ? '?${uri.query}' : ''} '
        'status=${response.statusCode}',
      );
      debugPrint('[Bootstrap] response body:\n${response.body}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      if (useAuth) {
        await SessionService.handleUnauthorized();
      }
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e, st) {
      if (kDebugMode && logResponseBody) {
        debugPrint('[Bootstrap] jsonDecode falló: $e\n$st');
      }
      return null;
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }
}
