import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/config/env.dart';
import 'package:vibe_trade_v1/models/notification_model.dart';
import 'package:vibe_trade_v1/services/api_response_utils.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/session_service.dart';

class NotificationsService {
  static final ValueNotifier<List<NotificationModel>> itemsNotifier =
      ValueNotifier(const <NotificationModel>[]);

  static String get _notificationsUrl => '$baseUrl/me/notifications';
  static String get _markReadUrl => '$baseUrl/me/notifications/mark-read';

  static int get unreadCount =>
      itemsNotifier.value.where((item) => !item.read).length;

  static void clear() {
    itemsNotifier.value = const <NotificationModel>[];
  }

  static Future<List<NotificationModel>> fetchNotifications({
    DateTime? from,
    DateTime? to,
    bool updateNotifier = true,
  }) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final query = <String, String>{};
    if (from != null) query['from'] = from.toUtc().toIso8601String();
    if (to != null) query['to'] = to.toUtc().toIso8601String();

    final uri = Uri.parse(_notificationsUrl).replace(
      queryParameters: query.isEmpty ? null : query,
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
          fallback:
              'No se pudieron cargar las notificaciones (${response.statusCode}).',
        ),
      );
    }

    final decoded = jsonDecode(response.body);
    final rawItems = _extractNotificationItems(decoded);
    final list = (rawItems ?? const <dynamic>[])
        .whereType<Map>()
        .map((item) => NotificationModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (updateNotifier) itemsNotifier.value = list;
    return list;
  }

  static List<dynamic>? _extractNotificationItems(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in const ['items', 'Items', 'notifications', 'Notifications', 'data', 'Data', 'value', 'Value']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return null;
  }

  static Future<void> markRead({List<String>? ids}) async {
    final token = await SessionService.getSavedToken();
    if (token == null) throw const UnauthorizedException();

    final response = await http.post(
      Uri.parse(_markReadUrl),
      headers: {
        'Authorization': SessionService.buildAuthorizationHeader(token),
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'ids': ids}),
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
              'No se pudieron marcar las notificaciones como leídas (${response.statusCode}).',
        ),
      );
    }

    final idSet = ids?.toSet();
    itemsNotifier.value = itemsNotifier.value
        .map((item) =>
            idSet == null || idSet.contains(item.id) ? item.copyWith(read: true) : item)
        .toList(growable: false);
  }
}
