import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/session_service.dart';
import 'package:vibe_trade_v1/utils/image_upload_limits.dart';

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
    if (token == null) throw const UnauthorizedException();
    await _validateImageFile(file);

    final response = await _postImage(file, token);
    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
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

  /// Sube bytes de imagen al mismo endpoint que [uploadAvatar].
  static Future<String> uploadImageBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    assertImageBytesUploadable(bytes);
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final request = http.MultipartRequest('POST', Uri.parse(_mediaBaseUrl));
    request.headers['Authorization'] = SessionService.buildAuthorizationHeader(token);
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: _imageMediaTypeForPath(filename),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401 || response.statusCode == 403) {
      await SessionService.handleUnauthorized();
      throw const UnauthorizedException();
    }
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
    await assertImageFileUploadable(file);
  }

  static Future<http.Response> _postImage(File file, String token) async {
    final request = http.MultipartRequest('POST', Uri.parse(_mediaBaseUrl));
    request.headers['Authorization'] = SessionService.buildAuthorizationHeader(token);
    request.headers['Accept'] = 'application/json';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: _imageMediaTypeForPath(file.path),
      ),
    );

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

  static MediaType _imageMediaTypeForPath(String path) {
    final ext = path.contains('.')
        ? path.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      case 'heic':
        return MediaType('image', 'heic');
      case 'heif':
        return MediaType('image', 'heif');
      case 'bmp':
        return MediaType('image', 'bmp');
      case 'avif':
        return MediaType('image', 'avif');
      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  static String? _extractMediaIdFromLooseBody(String rawBody) {
    final match = RegExp(
      r'''["']?(id|mediaId|media_id|_id)["']?\s*:\s*["']?([^"',}\s]+)''',
    ).firstMatch(rawBody);
    return match?.group(2)?.trim();
  }
}
