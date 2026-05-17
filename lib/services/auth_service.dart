import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/services/profile_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

class AuthService {
  static String get _requestCodeUrl => '$baseUrl/Auth/request-code';
  static String get _verifyUrl => '$baseUrl/Auth/verify';
  static String get _logoutUrl => '$baseUrl/Auth/logout';

  static String get authTokenKey => SessionService.authTokenKey;
  static String get authVerifyResponseKey =>
      SessionService.authVerifyResponseKey;
  static String get authUserKey => SessionService.authUserKey;

  static ValueNotifier<bool> get isLoggedInNotifier =>
      SessionService.isLoggedInNotifier;
  static ValueNotifier<UserProfileModel?> get currentUserNotifier =>
      SessionService.currentUserNotifier;

  static String resolveMediaUrl(String value) {
    return MediaService.resolveMediaUrl(value);
  }

  static Future<String> uploadAvatar(File file) {
    return MediaService.uploadAvatar(file);
  }

  static Future<void> requestRegisterCode({required String phone}) {
    return requestCode(phone: phone, mode: 'register');
  }

  static Future<void> requestCode({required String phone, String? mode}) async {
    final response = await http.post(
      Uri.parse(_requestCodeUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_codeRequestBody(phone, mode)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to request code: ${response.statusCode}');
    }
  }

  static Future<void> verifyRegisterCode({
    required String phone,
    required String code,
  }) {
    return verifyCode(phone: phone, code: code, mode: 'register');
  }

  static Future<void> verifyCode({
    required String phone,
    required String code,
    String? mode,
  }) async {
    final verifyBody = _verifyRequestBody(phone, code, mode);

    final response = await http.post(
      Uri.parse(_verifyUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(verifyBody),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo verificar el codigo (HTTP ${response.statusCode}). '
        'Respuesta: ${response.body.isNotEmpty ? response.body : "(vacia)"}',
      );
    }

    // Persistimos el token y dejamos limpio cualquier perfil de una sesion
    // anterior. El perfil correcto se trae a continuacion desde el backend.
    await SessionService.persistVerifyResponse(response.body);

    // Refrescamos desde `GET /Auth/session` cuando esta disponible; si falla por
    // red u otro error no-401, conservamos token y usuario devueltos por verify.
    try {
      await ProfileService.fetchCurrentUser();
    } on UnauthorizedException {
      rethrow;
    } catch (_) {
      final cached = SessionService.currentUserNotifier.value;
      if (cached == null || cached.isEmpty) {
        await SessionService.clearSession();
        rethrow;
      }
    }
  }

  static Future<String?> getSavedToken() {
    return SessionService.getSavedToken();
  }

  /// Carga la sesion local y la valida contra el backend. Si el token esta
  /// expirado o no es valido (401/403), [ProfileService.fetchCurrentUser]
  /// limpia la sesion y este metodo devuelve `false`. Errores transitorios de
  /// red no invalidan la sesion local.
  static Future<bool> hydrateSession() async {
    final hasLocalSession = await SessionService.hydrateSession();
    if (!hasLocalSession) return false;

    try {
      await ProfileService.fetchCurrentUser();
    } on UnauthorizedException {
      return false;
    } catch (_) {
      // Errores de red u otros: no invalidamos la sesion local para tolerar
      // momentos sin conexion. La proxima request autenticada podra detectar
      // un 401 real.
    }
    return SessionService.isLoggedInNotifier.value;
  }

  static Future<UserProfileModel?> getSavedUser() {
    return SessionService.getSavedUser();
  }

  /// Cierra la sesion: notifica al backend (best-effort) y siempre limpia el
  /// estado local. El perfil cacheado, token y respuesta del verify se
  /// eliminan aunque la llamada de logout falle, para garantizar que al
  /// volver a iniciar sesion no queden datos del usuario anterior.
  static Future<void> signOut() async {
    final token = await SessionService.getSavedToken();

    if (token != null) {
      try {
        await http.post(
          Uri.parse(_logoutUrl),
          headers: {
            'Authorization': SessionService.buildAuthorizationHeader(token),
          },
        );
      } catch (_) {
        // Errores de red no impiden cerrar sesion localmente.
      }
    }

    await SessionService.clearSession();
  }

  static Future<UserProfileModel> updateUserProfile({
    String? name,
    String? email,
    String? instagram,
    String? telegram,
    String? xAccount,
    String? avatarUrl,
  }) {
    return ProfileService.updateUserProfile(
      name: name,
      email: email,
      instagram: instagram,
      telegram: telegram,
      xAccount: xAccount,
      avatarUrl: avatarUrl,
    );
  }

  static Map<String, dynamic> _codeRequestBody(String phone, String? mode) {
    final body = <String, dynamic>{'phone': phone};
    if (mode != null && mode.isNotEmpty) body['mode'] = mode;
    return body;
  }

  /// El backend exige siempre las tres claves: `phone`, `code`, `mode`.
  /// En login normal [mode] es null y se envia `mode: ""`; en registro se envia
  /// `"register"`.
  static Map<String, dynamic> _verifyRequestBody(
    String phone,
    String code,
    String? mode,
  ) {
    return <String, dynamic>{'phone': phone, 'code': code, 'mode': mode ?? ''};
  }
}
