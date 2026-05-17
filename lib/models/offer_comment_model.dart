/// Modelo normalizado de comentario de la oferta
class OfferCommentNorm {
  final String id;
  final String? parentId;
  final String text;
  final OfferCommentAuthor author;
  final int createdAt;
  final int? likeCount;
  final bool? viewerLiked;

  OfferCommentNorm({
    required this.id,
    required this.parentId,
    required this.text,
    required this.author,
    required this.createdAt,
    this.likeCount,
    this.viewerLiked,
  });

  /// Indica si es una respuesta legacy (sufijo _legacy_ans)
  bool get isLegacyAnswer => id.endsWith('_legacy_ans');

  factory OfferCommentNorm.fromJson(Map<String, dynamic> json) {
    return OfferCommentNorm(
      id: json['id'] as String,
      parentId: json['parentId'] as String?,
      text: json['text'] as String,
      author: OfferCommentAuthor.fromJson(
        json['author'] as Map<String, dynamic>,
      ),
      createdAt: json['createdAt'] as int,
      likeCount: json['likeCount'] as int?,
      viewerLiked: json['viewerLiked'] as bool?,
    );
  }

  /// Parsea un único item devuelto por el backend
  /// (`OfferQaComment` enriquecido en `GET /Market/offers/{id}/qa`).
  /// Acepta los nombres legacy (`question`, `askedBy`) y los nuevos
  /// (`text`, `author`, `parentId`, `likeCount`, `viewerLiked`).
  /// Devuelve `null` si el item no puede normalizarse (sin id, sin texto
  /// o sin autor identificable).
  static OfferCommentNorm? fromApiQaItem(Map<String, dynamic> json) {
    final id = (json['id'] as Object?)?.toString().trim() ?? '';
    if (id.isEmpty) return null;

    final rawParent = (json['parentId'] as Object?)?.toString().trim();
    final parentId =
        (rawParent != null && rawParent.isNotEmpty) ? rawParent : null;

    final rawText = (json['text'] as Object?)?.toString().trim() ?? '';
    final rawQuestion =
        (json['question'] as Object?)?.toString().trim() ?? '';
    final text = rawText.isNotEmpty ? rawText : rawQuestion;
    if (text.isEmpty) return null;

    final authorMap = json['author'] is Map
        ? Map<String, dynamic>.from(json['author'] as Map)
        : null;
    final askedByMap = json['askedBy'] is Map
        ? Map<String, dynamic>.from(json['askedBy'] as Map)
        : null;

    Map<String, dynamic>? selected;
    if (authorMap != null &&
        ((authorMap['id'] as Object?)?.toString().trim().isNotEmpty ?? false)) {
      selected = authorMap;
    } else if (askedByMap != null &&
        ((askedByMap['id'] as Object?)?.toString().trim().isNotEmpty ?? false)) {
      selected = askedByMap;
    }
    if (selected == null) return null;

    final author = OfferCommentAuthor(
      id: (selected['id'] as Object?).toString(),
      name: (selected['name'] as Object?)?.toString() ?? '',
      trustScore: (selected['trustScore'] as num?)?.toInt() ?? 0,
    );

    final createdAtRaw = json['createdAt'];
    final createdAt = createdAtRaw is num
        ? createdAtRaw.toInt()
        : DateTime.now().millisecondsSinceEpoch;

    final likeCount = (json['likeCount'] as num?)?.toInt();
    final viewerLiked = json['viewerLiked'] as bool?;

    return OfferCommentNorm(
      id: id,
      parentId: parentId,
      text: text,
      author: author,
      createdAt: createdAt,
      likeCount: likeCount,
      viewerLiked: viewerLiked,
    );
  }

  /// Aplana el array `qa` que viene del backend a una lista ordenada por
  /// fecha. Replica el comportamiento de `normalizeOfferComments` del demo
  /// React: separa la respuesta legacy (`answer` + `answeredBy`) en un
  /// item hijo bajo el comentario padre.
  static List<OfferCommentNorm> normalizeFromQaList(List<dynamic> raw) {
    final out = <OfferCommentNorm>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final norm = OfferCommentNorm.fromApiQaItem(map);
      if (norm == null) continue;
      out.add(norm);

      final hasNewText = map.containsKey('text') &&
          ((map['text'] as Object?)?.toString().trim().isNotEmpty ?? false);
      final answer = (map['answer'] as Object?)?.toString().trim() ?? '';
      final answeredByRaw = map['answeredBy'];
      final hasParent = norm.parentId != null;
      if (!hasNewText &&
          answer.isNotEmpty &&
          answeredByRaw is Map &&
          !hasParent) {
        final answeredBy = Map<String, dynamic>.from(answeredByRaw);
        final answerAuthor = OfferCommentAuthor(
          id: (answeredBy['id'] as Object?)?.toString() ?? '',
          name: (answeredBy['name'] as Object?)?.toString() ?? '',
          trustScore: (answeredBy['trustScore'] as num?)?.toInt() ?? 0,
        );
        if (answerAuthor.id.isNotEmpty) {
          out.add(OfferCommentNorm(
            id: '${norm.id}_legacy_ans',
            parentId: norm.id,
            text: answer,
            author: answerAuthor,
            createdAt: norm.createdAt + 1,
            likeCount: 0,
            viewerLiked: false,
          ));
        }
      }
    }
    out.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parentId': parentId,
    'text': text,
    'author': author.toJson(),
    'createdAt': createdAt,
    'likeCount': likeCount,
    'viewerLiked': viewerLiked,
  };

  OfferCommentNorm copyWith({
    String? id,
    String? parentId,
    String? text,
    OfferCommentAuthor? author,
    int? createdAt,
    int? likeCount,
    bool? viewerLiked,
  }) {
    return OfferCommentNorm(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      viewerLiked: viewerLiked ?? this.viewerLiked,
    );
  }
}

/// Información del autor del comentario
class OfferCommentAuthor {
  final String id;
  final String name;
  final int trustScore;

  OfferCommentAuthor({
    required this.id,
    required this.name,
    required this.trustScore,
  });

  factory OfferCommentAuthor.fromJson(Map<String, dynamic> json) {
    return OfferCommentAuthor(
      id: json['id'] as String,
      name: json['name'] as String,
      trustScore: json['trustScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trustScore': trustScore,
  };
}

/// Contexto para resolver el nombre del autor del comentario
class OfferCommentAuthorContext {
  final String viewerId;
  final String viewerName;
  final Map<String, String> profileDisplayNames;

  OfferCommentAuthorContext({
    required this.viewerId,
    required this.viewerName,
    this.profileDisplayNames = const {},
  });
}

/// Resuelve el nombre visible del autor considerando el contexto actual
String resolveOfferCommentAuthorLabel(
  OfferCommentAuthor author,
  OfferCommentAuthorContext ctx,
) {
  // Si el autor es el usuario actual, usa su nombre actual
  if (author.id == ctx.viewerId && ctx.viewerName.trim().isNotEmpty) {
    return ctx.viewerName.trim();
  }

  // Si hay un nombre en el mapa de nombres de perfil (para perfiles renombrados)
  final fromMap = ctx.profileDisplayNames[author.id]?.trim();
  if (fromMap != null && fromMap.isNotEmpty) {
    return fromMap;
  }

  // Fallback: usa el nombre almacenado
  final trimmed = author.name.trim();
  return trimmed.isNotEmpty ? trimmed : 'Usuario';
}

/// Resultado de cambiar el like en un comentario
class ToggleLikeResult {
  final bool liked;
  final int likeCount;

  ToggleLikeResult({required this.liked, required this.likeCount});

  factory ToggleLikeResult.fromJson(Map<String, dynamic> json) {
    return ToggleLikeResult(
      liked: json['liked'] as bool,
      likeCount: json['likeCount'] as int? ?? 0,
    );
  }
}
