import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';

class SessionService {
  static const String authTokenKey = 'auth_token';
  static const String authVerifyResponseKey = 'auth_verify_response';
  static const String authUserKey = 'auth_user';

  static final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier(false);
  static final ValueNotifier<UserProfileModel?> currentUserNotifier =
      ValueNotifier(null);

  static Future<void> persistVerifyResponse(String responseBody) async {
    final prefs = await SharedPreferences.getInstance();
    final rawBody = responseBody.trim();
    await prefs.setString(authVerifyResponseKey, rawBody);

    if (rawBody.isEmpty) {
      await clearSession();
      return;
    }

    String? token;
    UserProfileModel? user;
    try {
      final dynamic decoded = jsonDecode(rawBody);
      token = ApiResponseUtils.extractToken(decoded);
      user = ApiResponseUtils.extractUser(decoded);
      if (token == null && decoded is String) token = decoded.trim();
    } catch (_) {
      token = rawBody;
    }

    await _persistUser(user, prefs);
    await _persistToken(token, prefs);
  }

  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(authTokenKey)?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  static Future<bool> hydrateSession() async {
    final token = await getSavedToken();
    currentUserNotifier.value = await getSavedUser();
    isLoggedInNotifier.value = token != null;
    return token != null;
  }

  static Future<UserProfileModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(authUserKey)?.trim();
    if (rawUser == null || rawUser.isEmpty) return null;

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is! Map) return null;
      final user = UserProfileModel.fromJson(Map<String, dynamic>.from(decoded));
      return user.isEmpty ? null : user;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveUser(UserProfileModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(authUserKey, jsonEncode(user.toJson()));
    currentUserNotifier.value = user;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokenKey);
    await prefs.remove(authVerifyResponseKey);
    await prefs.remove(authUserKey);
    isLoggedInNotifier.value = false;
    currentUserNotifier.value = null;
  }

  static String buildAuthorizationHeader(String token) {
    final trimmed = token.trim();
    return trimmed.toLowerCase().startsWith('bearer ') ? trimmed : 'Bearer $trimmed';
  }

  static Future<void> _persistUser(
    UserProfileModel? user,
    SharedPreferences prefs,
  ) async {
    if (user == null || user.isEmpty) {
      await prefs.remove(authUserKey);
      currentUserNotifier.value = null;
      return;
    }
    await prefs.setString(authUserKey, jsonEncode(user.toJson()));
    currentUserNotifier.value = user;
  }

  static Future<void> _persistToken(
    String? token,
    SharedPreferences prefs,
  ) async {
    final cleanToken = token?.trim();
    if (cleanToken == null || cleanToken.isEmpty) {
      isLoggedInNotifier.value = false;
      return;
    }
    await prefs.setString(authTokenKey, cleanToken);
    isLoggedInNotifier.value = true;
  }
}
