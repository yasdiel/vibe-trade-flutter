class NotificationModel {
  final String id;
  final String kind;
  final String title;
  final String body;
  final int createdAt;
  final bool read;
  final String? threadId;
  final String? offerId;
  final int trustScore;

  const NotificationModel({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.threadId,
    this.offerId,
    required this.trustScore,
  });

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      kind: kind,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read ?? this.read,
      threadId: threadId,
      offerId: offerId,
      trustScore: trustScore,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String pickString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return '';
    }

    int parseCreatedAt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) return parsed.millisecondsSinceEpoch;
      }
      return DateTime.now().millisecondsSinceEpoch;
    }

    final kind = pickString(const ['kind', 'Kind']);
    final threadId = pickString(const ['threadId', 'ThreadId']);
    final offerId = pickString(const ['offerId', 'OfferId']);
    final authorLabel = pickString(const ['authorLabel', 'AuthorLabel']);
    final trustScore =
        (json['authorTrustScore'] as num? ?? json['AuthorTrustScore'] as num?)
                ?.toInt() ??
            0;
    final title = _titleForKind(kind, authorLabel, trustScore);

    return NotificationModel(
      id: pickString(const ['id', 'Id']),
      kind: _normalizeKind(kind, offerId: offerId, threadId: threadId),
      title: title,
      body: pickString(const ['messagePreview', 'MessagePreview']),
      createdAt: parseCreatedAt(json['createdAtUtc'] ?? json['CreatedAtUtc']),
      read: json['readAtUtc'] != null || json['ReadAtUtc'] != null,
      threadId: threadId.isEmpty ? null : threadId,
      offerId: offerId.isEmpty ? null : offerId,
      trustScore: trustScore,
    );
  }

  static String _normalizeKind(
    String raw, {
    required String offerId,
    required String threadId,
  }) {
    if (raw == 'offer_like') return 'offer_like';
    if (raw == 'qa_comment_like') return 'qa_comment_like';
    if (raw == 'offer_comment') return 'offer_comment';
    if (raw == 'peer_party_exited') return 'peer_party_exited';
    if (raw == 'store_trust_penalty') return 'store_trust_penalty';
    if (raw.startsWith('route_') || raw.startsWith('rl_')) return raw;
    if (offerId.trim().isNotEmpty && threadId.trim().isEmpty) {
      return 'offer_comment';
    }
    return 'chat_message';
  }

  static String _titleForKind(String kind, String authorLabel, int trustScore) {
    if (kind == 'peer_party_exited') {
      return 'Salida del chat (acuerdo aceptado)';
    }
    if (kind == 'store_trust_penalty') return 'Confianza de tu tienda';
    if (kind == 'route_tramo_seller_expelled') {
      return 'Te retiraron de la operación';
    }
    if (kind == 'rl_ownership_granted') return 'Titularidad del paquete';
    final label = authorLabel.trim().isEmpty ? 'VibeTrade' : authorLabel.trim();
    return '$label · confianza $trustScore';
  }
}
