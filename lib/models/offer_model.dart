class OfferAuthor {
  final String id;
  final String name;
  final int? trustScore;

  const OfferAuthor({
    required this.id,
    required this.name,
    this.trustScore,
  });

  factory OfferAuthor.fromJson(Map<String, dynamic> json) {
    return OfferAuthor(
      id: (json['id'] as Object?)?.toString() ?? '',
      name: ((json['name'] as Object?)?.toString() ?? '').trim(),
      trustScore:
          _readTrustScore(json, const ['trustScore', 'TrustScore']),
    );
  }
}

int? _readTrustScore(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v is num) return v.toInt();
    final p = int.tryParse(v?.toString() ?? '');
    if (p != null) return p;
  }
  return null;
}

int? _readOfferInt(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v == null) continue;
    if (v is num) return v.toInt();
    final p = int.tryParse(v.toString());
    if (p != null) return p;
  }
  return null;
}

class OfferQuestion {
  final String id;
  final String question;
  final String text;
  final OfferAuthor? askedBy;
  final OfferAuthor? author;
  final DateTime? createdAt;

  const OfferQuestion({
    required this.id,
    required this.question,
    required this.text,
    this.askedBy,
    this.author,
    this.createdAt,
  });

  factory OfferQuestion.fromJson(Map<String, dynamic> json) {
    final askedByRaw =
        json['askedBy'] ?? json['AskedBy'] ?? json['asked_by'];
    final authorRaw =
        json['author'] ?? json['Author'] ?? json['answeredBy'];
    final createdAtRaw =
        json['createdAt'] ?? json['CreatedAt'] ?? json['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is num) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw.toInt());
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }
    Map<String, dynamic>? coerceMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    final askedMap = coerceMap(askedByRaw);
    final authorMap = coerceMap(authorRaw);

    final rawQuestion = ((json['question'] as Object?)?.toString() ?? '').trim();
    final rawText = ((json['text'] as Object?)?.toString() ?? '').trim();
    final answer = ((json['answer'] as Object?)?.toString() ?? '').trim();
    // Persistencia `OfferQaComment`: texto libre + opcional `Answer` del vendedor.
    final mergedText = _mergeOfferQaVisibleText(rawText, answer, rawQuestion);

    return OfferQuestion(
      id: ((json['id'] ?? json['Id']) as Object?)?.toString().trim() ?? '',
      question: rawQuestion,
      text: mergedText,
      askedBy: askedMap != null ? OfferAuthor.fromJson(askedMap) : null,
      author: authorMap != null ? OfferAuthor.fromJson(authorMap) : null,
      createdAt: createdAt,
    );
  }
}

String _mergeOfferQaVisibleText(
  String rawText,
  String answer,
  String question,
) {
  if (rawText.isNotEmpty) {
    return answer.isNotEmpty && !rawText.contains(answer)
        ? '$rawText\n$answer'.trim()
        : rawText;
  }
  if (answer.isNotEmpty) return answer;
  return question;
}

/// Modelo cliente de [`HomeOfferViewDto`] (`GET Recommendations`).
class OfferModel {
  final String id;
  final String storeId;
  final String title;

  /// Texto preformateado tal como viene del backend (p.ej. "6 USD").
  final String price;
  final String currency;
  final List<String> acceptedCurrencies;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<OfferQuestion> qa;
  final int publicCommentCount;
  final int offerLikeCount;
  final bool viewerLikedOffer;

  /// Publicacion de ruta emergente (`emo_*`); en web muestra flujo distinto a "Comprar".
  final bool isEmergentRoutePublication;

  /// Oferta base en catalogo cuando [isEmergentRoutePublication] es true; tambien al crear hilo de chat.
  final String? emergentBaseOfferId;

  const OfferModel({
    required this.id,
    required this.storeId,
    required this.title,
    required this.price,
    required this.currency,
    required this.acceptedCurrencies,
    required this.description,
    required this.tags,
    required this.imageUrl,
    required this.imageUrls,
    required this.qa,
    required this.publicCommentCount,
    required this.offerLikeCount,
    required this.viewerLikedOffer,
    this.isEmergentRoutePublication = false,
    this.emergentBaseOfferId,
  });

  OfferModel copyWith({
    String? id,
    String? storeId,
    String? title,
    String? price,
    String? currency,
    List<String>? acceptedCurrencies,
    String? description,
    List<String>? tags,
    String? imageUrl,
    List<String>? imageUrls,
    List<OfferQuestion>? qa,
    int? publicCommentCount,
    int? offerLikeCount,
    bool? viewerLikedOffer,
    bool? isEmergentRoutePublication,
    String? emergentBaseOfferId,
  }) {
    return OfferModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      title: title ?? this.title,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      acceptedCurrencies: acceptedCurrencies ?? this.acceptedCurrencies,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      qa: qa ?? this.qa,
      publicCommentCount: publicCommentCount ?? this.publicCommentCount,
      offerLikeCount: offerLikeCount ?? this.offerLikeCount,
      viewerLikedOffer: viewerLikedOffer ?? this.viewerLikedOffer,
      isEmergentRoutePublication:
          isEmergentRoutePublication ?? this.isEmergentRoutePublication,
      emergentBaseOfferId: emergentBaseOfferId ?? this.emergentBaseOfferId,
    );
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final rawTags =
        ((json['tags'] ?? json['Tags']) as List?) ?? const <dynamic>[];
    final rawImages = ((json['imageUrls'] ?? json['ImageUrls']) as List?) ??
        const <dynamic>[];
    final rawQa =
        ((json['qa'] ?? json['Qa']) as List?) ?? const <dynamic>[];
    final rawAcceptedCurrencies =
        ((json['acceptedCurrencies'] ?? json['AcceptedCurrencies']) as List?) ??
            const <dynamic>[];

    final primaryImage = json['imageUrl'] ?? json['ImageUrl'];
    final imageUrlValue = primaryImage == null
        ? ''
        : primaryImage is String
            ? primaryImage.trim()
            : primaryImage.toString().trim();

    final emergentBaseRaw =
        json['emergentBaseOfferId'] ?? json['EmergentBaseOfferId'];
    final emergentBaseOfferId = emergentBaseRaw == null
        ? null
        : emergentBaseRaw.toString().trim().isEmpty
            ? null
            : emergentBaseRaw.toString().trim();

    final emergentPub = json['isEmergentRoutePublication'] ??
        json['IsEmergentRoutePublication'];
    final isEmergentRoutePublication = emergentPub is bool
        ? emergentPub
        : emergentPub is num
            ? emergentPub != 0
            : emergentPub is String
                ? emergentPub.trim().toLowerCase() == 'true'
                : false;

    return OfferModel(
      id: ((json['id'] ?? json['Id']) as Object?)?.toString().trim() ?? '',
      storeId: ((json['storeId'] ?? json['StoreId']) as Object?)
              ?.toString()
              .trim() ??
          '',
      title: ((json['title'] ?? json['Title']) as Object?)?.toString().trim() ??
          '',
      price: ((json['price'] ?? json['Price']) as Object?)
              ?.toString()
              .trim() ??
          '',
      currency: ((json['currency'] ?? json['Currency']) as Object?)
              ?.toString()
              .trim() ??
          '',
      acceptedCurrencies: rawAcceptedCurrencies
          .map((v) => v?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      description:
          ((json['description'] ?? json['Description']) as Object?)
                  ?.toString()
                  .trim() ??
              '',
      tags: rawTags
          .map((v) => v?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      imageUrl:
          imageUrlValue.isEmpty ? null : imageUrlValue,
      imageUrls: rawImages
          .map((v) => v?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      qa: rawQa
          .whereType<Map>()
          .map((map) =>
              OfferQuestion.fromJson(Map<String, dynamic>.from(map)))
          .toList(growable: false),
      publicCommentCount: _readOfferInt(
            json,
            const ['publicCommentCount', 'PublicCommentCount'],
          ) ??
          0,
      offerLikeCount:
          _readOfferInt(json, const ['offerLikeCount', 'OfferLikeCount']) ??
              0,
      viewerLikedOffer: ((json['viewerLikedOffer'] ?? json['ViewerLikedOffer'])
              as bool?) ??
          false,
      isEmergentRoutePublication: isEmergentRoutePublication,
      emergentBaseOfferId: emergentBaseOfferId,
    );
  }

  /// Las primeras palabras de `tags` traen, en orden, la categoria, la
  /// condicion (Nuevo/Usado) y el tipo (Producto/Servicio). Devolvemos solo
  /// la primera porque suele ser la categoria y es lo que mostramos como
  /// chip principal.
  String? get primaryCategoryTag => tags.isEmpty ? null : tags.first;

  bool get isService =>
      tags.any((tag) => tag.toLowerCase() == 'servicio');

  bool get isProduct =>
      tags.any((tag) => tag.toLowerCase() == 'producto');

  /// Id de oferta que usa la API de hilos (base catalogo si es emergente).
  String get catalogThreadOfferId {
    final b = emergentBaseOfferId?.trim();
    if (b != null && b.isNotEmpty) return b;
    return id.trim();
  }
}
