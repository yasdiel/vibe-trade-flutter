import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

class MediaService {
  static String get _mediaBaseUrl => '$baseUrl/media';

  static String resolveMediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase().startsWith('http')) {
      return trimmed;
    }
    if (trimmed.startsWith('api/v1/')) {
      return '${Uri.parse(baseUrl).origin}/$trimmed';
    }
    if (trimmed.startsWith('/api/v1/')) {
      return '${Uri.parse(baseUrl).origin}$trimmed';
    }
    return trimmed.startsWith('/') ? '$baseUrl$trimmed' : '$_mediaBaseUrl/$trimmed';
  }

  static Future<String> uploadAvatar(File file) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw Exception('No hay una sesion activa.');
    await _validateImageFile(file);

    final response = await _postImage(file, token);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudo subir la imagen (status ${response.statusCode}).',
        ),
      );
    }

    final mediaId = _extractMediaId(response.body);
    if (mediaId == null || mediaId.isEmpty) {
      throw Exception('No se pudo obtener el id de la imagen.');
    }
    return '/api/v1/media/$mediaId';
  }

  static Future<void> _validateImageFile(File file) async {
    if (!await file.exists()) throw Exception('El archivo de imagen no existe.');
    if (await file.length() == 0) throw Exception('El archivo de imagen esta vacio.');
  }

  static Future<http.Response> _postImage(File file, String token) async {
    final request = http.MultipartRequest('POST', Uri.parse(_mediaBaseUrl));
    request.headers['Authorization'] = SessionService.buildAuthorizationHeader(token);
    request.headers['Accept'] = 'application/json';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  static String? _extractMediaId(String responseBody) {
    final rawBody = responseBody.trim();
    if (rawBody.isEmpty) return null;

    try {
      return _findMediaId(jsonDecode(rawBody));
    } catch (_) {
      return _extractMediaIdFromLooseBody(rawBody);
    }
  }

  static String? _findMediaId(dynamic value) {
    if (value is String) return value.trim().isEmpty ? null : value.trim();
    if (value is num) return value.toString();
    if (value is! Map) return null;

    const keys = ['id', 'mediaId', 'media_id', '_id'];
    for (final key in keys) {
      final id = _findMediaId(value[key]);
      if (id != null && id.isNotEmpty) return id;
    }
    return _findMediaId(value['data']);
  }

  static String? _extractMediaIdFromLooseBody(String rawBody) {
    final match = RegExp(
      r'''["']?(id|mediaId|media_id|_id)["']?\s*:\s*["']?([^"',}\s]+)''',
    ).firstMatch(rawBody);
    return match?.group(2)?.trim();
  }
}
