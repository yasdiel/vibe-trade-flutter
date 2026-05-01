import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/models/user_profile_model.dart';

class ApiResponseUtils {
  static String extractErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    final rawBody = response.body.trim();
    if (rawBody.isEmpty) return fallback;

    try {
      final dynamic decoded = jsonDecode(rawBody);
      return _findMessage(decoded) ?? fallback;
    } catch (_) {
      return rawBody;
    }
  }

  static String? extractToken(dynamic value) {
    if (value is String) return _nonEmpty(value);

    if (value is Map) {
      const keys = [
        'token',
        'accessToken',
        'access_token',
        'jwt',
        'jwtToken',
        'idToken',
        'id_token',
        'authToken',
        'auth_token',
        'bearerToken',
        'bearer_token',
      ];
      for (final key in keys) {
        final token = extractToken(value[key]);
        if (token != null) return token;
      }
      return _firstFromIterable(value.values, extractToken);
    }

    if (value is List) return _firstFromIterable(value, extractToken);
    return null;
  }

  static UserProfileModel? extractUser(dynamic value) {
    if (value is! Map) return null;

    final directUser = _userFromMap(value['user']);
    if (directUser != null) return directUser;

    final data = value['data'];
    if (data is Map) {
      final dataUser = _userFromMap(data['user']);
      if (dataUser != null) return dataUser;

      final directData = _userFromMap(data);
      if (directData != null) return directData;
    }

    final directResponse = _userFromMap(value);
    if (directResponse != null) return directResponse;

    return _firstFromIterable(value.values, extractUser);
  }

  static UserProfileModel extractUserFromProfileResponse(
    String responseBody,
    UserProfileModel fallbackUser,
  ) {
    final rawBody = responseBody.trim();
    if (rawBody.isEmpty) return fallbackUser;

    try {
      final extractedUser = extractUser(jsonDecode(rawBody));
      if (extractedUser == null || extractedUser.isEmpty) return fallbackUser;
      return _mergeUser(extractedUser, fallbackUser);
    } catch (_) {
      return fallbackUser;
    }
  }

  static String? _findMessage(dynamic value) {
    if (value is String) return _nonEmpty(value);
    if (value is List) return _firstFromIterable(value, _findMessage);
    if (value is! Map) return null;

    const keys = ['message', 'error', 'detail', 'details', 'title', 'description'];
    for (final key in keys) {
      final message = _findMessage(value[key]);
      if (message != null) return message;
    }
    return _firstFromIterable(value.values, _findMessage);
  }

  static UserProfileModel? _userFromMap(dynamic value) {
    if (value is! Map) return null;
    final user = UserProfileModel.fromJson(Map<String, dynamic>.from(value));
    return user.isEmpty ? null : user;
  }

  static UserProfileModel _mergeUser(
    UserProfileModel user,
    UserProfileModel fallback,
  ) {
    return UserProfileModel(
      id: user.id.isNotEmpty ? user.id : fallback.id,
      name: user.name.isNotEmpty ? user.name : fallback.name,
      email: user.email.isNotEmpty ? user.email : fallback.email,
      phone: user.phone.isNotEmpty ? user.phone : fallback.phone,
      imageUrl: user.imageUrl.isNotEmpty ? user.imageUrl : fallback.imageUrl,
      instagram: user.instagram.isNotEmpty ? user.instagram : fallback.instagram,
      xHandle: user.xHandle.isNotEmpty ? user.xHandle : fallback.xHandle,
      telegram: user.telegram.isNotEmpty ? user.telegram : fallback.telegram,
      trustScore: (user.trustScore ?? 0) > 0
          ? user.trustScore
          : fallback.trustScore,
    );
  }

  static String? _nonEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static T? _firstFromIterable<T>(
    Iterable<dynamic> values,
    T? Function(dynamic value) mapper,
  ) {
    for (final value in values) {
      final mapped = mapper(value);
      if (mapped != null) return mapped;
    }
    return null;
  }
}
