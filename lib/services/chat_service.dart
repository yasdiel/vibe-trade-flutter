import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

/// API de chat (`/api/v1/chat/...`), alineada con el demo en React.
///
/// Endpoints (ver `ChatController` en el backend):
/// - `POST   /chat/threads` — crea o reutiliza el hilo comprador↔vendedor.
/// - `GET    /chat/threads` — lista de hilos del usuario actual.
/// - `GET    /chat/threads/{id}/messages` — historial visible.
/// - `POST   /chat/threads/{id}/messages` — publica un mensaje.
/// - `DELETE /chat/threads/{id}` — borra el hilo de la lista del usuario.
class ChatService {
  static String get _threadsBase => '$baseUrl/chat/threads';

  static Future<Map<String, dynamic>> createOrGetChatThread({
    required String offerId,
    bool purchaseIntent = true,
    bool forceNew = false,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final response = await http.post(
      Uri.parse(_threadsBase),
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'offerId': offerId,
        'purchaseIntent': purchaseIntent,
        'forceNew': forceNew,
      }),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode == 400) {
      try {
        final j = jsonDecode(response.body);
        if (j is Map && (j['error']?.toString().trim() == 'cannot_message_self')) {
          throw const ChatCannotMessageSelfException();
        }
      } catch (e) {
        if (e is ChatCannotMessageSelfException) rethrow;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo abrir el chat (${response.statusCode}).',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception('Respuesta de chat invalida.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static Future<void> postChatMessage(
    String threadId,
    Map<String, dynamic> body,
  ) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final tid = threadId.trim();
    final uri = Uri.parse(
      '$baseUrl/chat/threads/${Uri.encodeComponent(tid)}/messages',
    );
    final response = await http.post(
      uri,
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo enviar el mensaje (${response.statusCode}).',
        ),
      );
    }
  }

  static Future<void> postChatTextMessage(String threadId, String text) async {
    await postChatMessage(threadId, {'type': 'text', 'text': text});
  }

  /// `GET /chat/threads` — resumen de los hilos donde participa el viewer.
  /// Cada elemento es un `ChatThreadSummaryDto` (camelCase).
  static Future<List<Map<String, dynamic>>> fetchChatThreads() async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final response = await http.get(
      Uri.parse(_threadsBase),
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
              'No se pudieron cargar tus chats (${response.statusCode}).',
        ),
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) return const <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }

  /// `DELETE /chat/threads/{id}` — quita el hilo de la lista del viewer.
  static Future<void> deleteChatThread(String threadId) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final tid = threadId.trim();
    final uri = Uri.parse(
      '$baseUrl/chat/threads/${Uri.encodeComponent(tid)}',
    );
    final response = await http.delete(
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
    if (response.statusCode == 404) return;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo borrar el chat (${response.statusCode}).',
        ),
      );
    }
  }

  static Future<List<Map<String, dynamic>>> fetchChatMessages(
    String threadId,
  ) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final tid = threadId.trim();
    final uri = Uri.parse(
      '$baseUrl/chat/threads/${Uri.encodeComponent(tid)}/messages',
    );
    final response = await http.get(
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
          fallback: 'No se pudieron cargar los mensajes (${response.statusCode}).',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
  }
}
