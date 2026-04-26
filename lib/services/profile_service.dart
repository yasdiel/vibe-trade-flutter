import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

class ProfileService {
  static String get _profileUrl => '$baseUrl/Auth/profile';

  static Future<UserProfileModel> updateUserProfile({
    String? name,
    String? email,
    String? instagram,
    String? telegram,
    String? xAccount,
    String? avatarUrl,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw Exception('No hay una sesion activa.');

    final currentUser =
        SessionService.currentUserNotifier.value ?? await SessionService.getSavedUser();
    final mergedUser = _mergeUser(
      currentUser,
      name: name,
      email: email,
      instagram: instagram,
      telegram: telegram,
      xAccount: xAccount,
      avatarUrl: avatarUrl,
    );
    final response = await _patchProfile(token, _buildBody(mergedUser, (
      instagram: instagram,
      telegram: telegram,
      xAccount: xAccount,
      avatarUrl: avatarUrl,
    )));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiResponseUtils.extractErrorMessage(
          response,
          fallback: 'No se pudieron guardar los cambios del perfil.',
        ),
      );
    }

    final updatedUser = ApiResponseUtils.extractUserFromProfileResponse(
      response.body,
      mergedUser,
    );
    await SessionService.saveUser(updatedUser);
    return updatedUser;
  }

  static Future<http.Response> _patchProfile(
    String token,
    Map<String, dynamic> body,
  ) {
    return http.patch(
      Uri.parse(_profileUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': SessionService.buildAuthorizationHeader(token),
      },
      body: jsonEncode(body),
    );
  }

  static Map<String, dynamic> _buildBody(
    UserProfileModel user,
    ({
      String? instagram,
      String? telegram,
      String? xAccount,
      String? avatarUrl,
    }) changes,
  ) {
    final body = <String, dynamic>{'name': user.name, 'email': user.email};
    _addOptional(body, 'instagram', changes.instagram);
    _addOptional(body, 'telegram', changes.telegram);
    _addOptional(body, 'xAccount', changes.xAccount);
    _addOptional(body, 'avatarUrl', changes.avatarUrl);
    return body;
  }

  static UserProfileModel _mergeUser(
    UserProfileModel? currentUser, {
    String? name,
    String? email,
    String? instagram,
    String? telegram,
    String? xAccount,
    String? avatarUrl,
  }) {
    return UserProfileModel(
      id: currentUser?.id ?? '',
      name: name ?? currentUser?.name ?? '',
      email: email ?? currentUser?.email ?? '',
      phone: currentUser?.phone ?? '',
      imageUrl: avatarUrl ?? currentUser?.imageUrl ?? '',
      instagram: instagram ?? currentUser?.instagram ?? '',
      xHandle: xAccount ?? currentUser?.xHandle ?? '',
      telegram: telegram ?? currentUser?.telegram ?? '',
      trustScore: currentUser?.trustScore,
    );
  }

  static void _addOptional(
    Map<String, dynamic> body,
    String key,
    String? value,
  ) {
    if (value == null) return;
    body[key] = value.trim().isEmpty ? null : value.trim();
  }
}
