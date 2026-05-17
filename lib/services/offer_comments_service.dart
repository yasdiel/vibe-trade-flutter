import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/offer_comment_model.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

/// Servicio para gestionar comentarios públicos (Q&A) de las ofertas.
///
/// Endpoints (ver `MarketController` en el backend):
/// - `POST {baseUrl}/Market/inquiries` — publica un comentario o respuesta
///   (requiere `Authorization: Bearer`).
/// - `GET  {baseUrl}/Market/offers/{offerId}/qa` — array enriquecido de
///   comentarios para refrescar la ficha (anónimo permitido; con sesión se
///   incluye `viewerLiked`).
/// - `POST {baseUrl}/Market/offers/{offerId}/qa/{qaCommentId}/like` —
///   alterna el like en un comentario (requiere `Authorization: Bearer`).
abstract class OfferCommentsService {
  static String get _inquiriesUrl => '$baseUrl/Market/inquiries';

  static String _qaListUrl(String offerId) =>
      '$baseUrl/Market/offers/${Uri.encodeComponent(offerId.trim())}/qa';

  static String _qaCommentLikeUrl(String offerId, String qaCommentId) =>
      '$baseUrl/Market/offers/${Uri.encodeComponent(offerId.trim())}'
      '/qa/${Uri.encodeComponent(qaCommentId.trim())}/like';

  /// `POST /Market/inquiries` — publica un comentario o respuesta a otro.
  ///
  /// Requiere sesión activa. El servidor toma `askedBy` desde la sesión,
  /// pero el body lo incluye porque el record `PostInquiryBody` lo exige.
  static Future<OfferCommentNorm> submitOfferQuestion(
    String offerId,
    String question,
    OfferCommentAuthor askedBy, {
    String? parentId,
    bool logResponseBody = false,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final trimmedOfferId = offerId.trim();
    final trimmedText = question.trim();
    if (trimmedOfferId.isEmpty || trimmedText.isEmpty) {
      throw ArgumentError('offerId y texto no pueden estar vacíos.');
    }

    final body = <String, dynamic>{
      'offerId': trimmedOfferId,
      'text': trimmedText,
      'question': trimmedText,
      'parentId': (parentId != null && parentId.trim().isNotEmpty)
          ? parentId.trim()
          : null,
      'askedBy': askedBy.toJson(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    final uri = Uri.parse(_inquiriesUrl);
    final headers = <String, String>{
      'Authorization': SessionService.buildAuthorizationHeader(token),
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (kDebugMode && logResponseBody) {
      debugPrint(
        '[OfferComments] POST ${uri.scheme}://${uri.host}${uri.path} '
        'status=${response.statusCode}',
      );
      debugPrint('[OfferComments] response body:\n${response.body}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo enviar el comentario.',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Respuesta inválida del servidor al publicar comentario.');
    }

    final norm = OfferCommentNorm.fromApiQaItem(
      Map<String, dynamic>.from(decoded),
    );
    if (norm == null) {
      throw Exception('No se pudo interpretar el comentario creado.');
    }
    return norm;
  }

  /// `POST /Market/offers/{offerId}/qa/{qaCommentId}/like` — alterna el like.
  ///
  /// El backend marca esta ruta como `[AllowAnonymous]` pero exige
  /// `likerKey` autenticado: si no hay sesión devuelve 401.
  static Future<ToggleLikeResult> toggleOfferQaCommentLike(
    String offerId,
    String qaCommentId, {
    bool logResponseBody = false,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final uri = Uri.parse(_qaCommentLikeUrl(offerId, qaCommentId));
    final headers = <String, String>{
      'Authorization': SessionService.buildAuthorizationHeader(token),
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final response = await http.post(uri, headers: headers, body: '{}');

    if (kDebugMode && logResponseBody) {
      debugPrint(
        '[OfferComments] POST ${uri.scheme}://${uri.host}${uri.path} '
        'status=${response.statusCode}',
      );
      debugPrint('[OfferComments] response body:\n${response.body}');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo actualizar el me gusta.',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return ToggleLikeResult(liked: false, likeCount: 0);
    }
    return ToggleLikeResult.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// `GET /Market/offers/{offerId}/qa` — comentarios enriquecidos.
  ///
  /// Anónimo permitido: si hay sesión se envía el Bearer para que el
  /// servidor incluya `viewerLiked` por comentario. Devuelve la lista
  /// normalizada (plana, ordenada por `createdAt`, con respuestas legacy
  /// expandidas en hijos `_legacy_ans`).
  static Future<List<OfferCommentNorm>> fetchOfferComments(
    String offerId, {
    bool logResponseBody = false,
  }) async {
    final token = await SessionService.getSavedToken();
    final uri = Uri.parse(_qaListUrl(offerId));

    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = SessionService.buildAuthorizationHeader(token);
    }

    final response = await http.get(uri, headers: headers);

    if (kDebugMode && logResponseBody) {
      final mode = token != null ? 'authenticated' : 'guest';
      debugPrint(
        '[OfferComments] GET $mode ${uri.scheme}://${uri.host}${uri.path} '
        'status=${response.statusCode}',
      );
      debugPrint('[OfferComments] response body:\n${response.body}');
    }

    if (response.statusCode == 404) {
      return const <OfferCommentNorm>[];
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudieron cargar los comentarios.',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) return const <OfferCommentNorm>[];
    return OfferCommentNorm.normalizeFromQaList(decoded);
  }
}
