import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/services/profile_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

class AuthService {
  static String get _requestCodeUrl => '$baseUrl/Auth/request-code';
  static String get _verifyUrl => '$baseUrl/Auth/verify';
  static String get _logoutUrl => '$baseUrl/Auth/logout';

  static String get authTokenKey => SessionService.authTokenKey;
  static String get authVerifyResponseKey => SessionService.authVerifyResponseKey;
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
    final response = await http.post(
      Uri.parse(_verifyUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_verifyRequestBody(phone, code, mode)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to verify code: ${response.statusCode}');
    }
    await SessionService.persistVerifyResponse(response.body);
    await ProfileService.fetchCurrentUser();
  }

  static Future<String?> getSavedToken() {
    return SessionService.getSavedToken();
  }

  static Future<bool> hydrateSession() async {
    final isLoggedIn = await SessionService.hydrateSession();
    if (isLoggedIn) {
      await ProfileService.fetchCurrentUser();
    }
    return isLoggedIn;
  }

  static Future<UserProfileModel?> getSavedUser() {
    return SessionService.getSavedUser();
  }

  static Future<void> signOut() async {
    final token = await SessionService.getSavedToken();
    if (token == null) {
      throw Exception('No hay una sesion activa para cerrar.');
    }

    final response = await http.post(
      Uri.parse(_logoutUrl),
      headers: {'Authorization': SessionService.buildAuthorizationHeader(token)},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo cerrar la sesion. Intenta nuevamente.');
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

  static Map<String, dynamic> _verifyRequestBody(
    String phone,
    String code,
    String? mode,
  ) {
    final body = <String, dynamic>{'phone': phone, 'code': code};
    if (mode != null && mode.isNotEmpty) body['mode'] = mode;
    return body;
  }
}
