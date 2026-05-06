class StoreModel {
  final String id;
  final String name;
  final String description;
  final List<String> categories;
  final bool hasOwnTransport;
  final String website;
  final double? latitude;
  final double? longitude;
  final String imagePath;
  final DateTime createdAt;
  final bool isVerified;
  final int trustScore;
  final int productsCount;
  final int servicesCount;

  const StoreModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categories,
    required this.hasOwnTransport,
    required this.website,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
    required this.createdAt,
    required this.isVerified,
    required this.trustScore,
    this.productsCount = 0,
    this.servicesCount = 0,
  });

  bool get hasLocation => latitude != null && longitude != null;

  StoreModel copyWith({
    String? name,
    String? description,
    List<String>? categories,
    bool? hasOwnTransport,
    String? website,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    String? imagePath,
    DateTime? createdAt,
    bool? isVerified,
    int? trustScore,
    int? productsCount,
    int? servicesCount,
  }) {
    return StoreModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      hasOwnTransport: hasOwnTransport ?? this.hasOwnTransport,
      website: website ?? this.website,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      trustScore: trustScore ?? this.trustScore,
      productsCount: productsCount ?? this.productsCount,
      servicesCount: servicesCount ?? this.servicesCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categories': categories,
      'hasOwnTransport': hasOwnTransport,
      'website': website,
      'latitude': latitude,
      'longitude': longitude,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'trustScore': trustScore,
      'productsCount': productsCount,
      'servicesCount': servicesCount,
    };
  }

  /// Payload del Market workspace (`pitch`, `transportIncluded`, `websiteUrl`,
  /// `avatarUrl`, `location`, etc.).
  factory StoreModel.fromWorkspaceApi(Map<String, dynamic> json) {
    String workspaceStr(dynamic value) {
      if (value == null) return '';
      if (value is String) return value.trim();
      return value.toString().trim();
    }

    double? lat, lng;
    final loc = json['location'];
    if (loc is Map) {
      final lm = Map<String, dynamic>.from(loc);
      lat = (lm['lat'] as num?)?.toDouble();
      lng = (lm['lng'] as num?)?.toDouble();
    }

    final pitch = workspaceStr(json['pitch']);
    final fallbackDesc = workspaceStr(json['description']);

    var websiteRaw = workspaceStr(json['websiteUrl']);
    if (websiteRaw.isEmpty) {
      websiteRaw = workspaceStr(json['website']);
    }

    final categoriesRaw = json['categories'];
    final cats = categoriesRaw is List
        ? categoriesRaw
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .map((e) => e.toString().trim())
              .toList(growable: false)
        : const <String>[];

    final avatar = workspaceStr(json['avatarUrl'] ?? json['imagePath']);

    return StoreModel(
      id: workspaceStr(json['id']),
      name: workspaceStr(json['name']),
      description: pitch.isNotEmpty ? pitch : fallbackDesc,
      categories: List<String>.unmodifiable(cats),
      hasOwnTransport: (json['transportIncluded'] as bool?) ??
          (json['hasOwnTransport'] as bool?) ??
          false,
      website: websiteRaw,
      latitude: lat,
      longitude: lng,
      imagePath: avatar,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      isVerified: (json['verified'] as bool?) ??
          (json['isVerified'] as bool?) ??
          false,
      trustScore:
          ((json['trustScore'] as num?)?.toInt() ?? 0).clamp(0, 100),
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      servicesCount: (json['servicesCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      categories: ((json['categories'] as List?) ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      hasOwnTransport: (json['hasOwnTransport'] as bool?) ?? false,
      website: (json['website'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imagePath: (json['imagePath'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      isVerified: (json['isVerified'] as bool?) ?? false,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 80,
      productsCount: (json['productsCount'] as num?)?.toInt() ?? 0,
      servicesCount: (json['servicesCount'] as num?)?.toInt() ?? 0,
    );
  }
}
