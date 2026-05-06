/// Ubicacion WGS84. El API de badge (`MarketCatalogStoreBadgeJson`) solo envia
/// `{ "lat": number, "lng": number }` cuando hay coordenadas en BD.
class StoreLocation {
  final double latitude;
  final double longitude;

  const StoreLocation({required this.latitude, required this.longitude});

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    double? lat = (json['lat'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble();
    double? lng = (json['lng'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble();
    return StoreLocation(
      latitude: lat ?? 0.0,
      longitude: lng ?? 0.0,
    );
  }

  bool get looksValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      !(latitude.abs() < 1e-9 && longitude.abs() < 1e-9);
}

/// Forma compatible con [`StoreProfileWorkspaceData`] del batch de recomendaciones.
class StoreBadgeModel {
  final String id;
  final String name;
  final bool verified;
  final bool transportIncluded;
  final int trustScore;
  final String ownerUserId;
  /// Coleccion copiada de `categories` (jsonb array de strings en servidor).
  final List<String> categories;
  final StoreLocation? location;
  /// Pitch de catalogo (campo `pitch`).
  final String pitch;
  final String websiteUrl;

  /// Opcional en API (`avatarUrl`).
  final String? avatarUrl;

  const StoreBadgeModel({
    required this.id,
    required this.name,
    required this.verified,
    required this.transportIncluded,
    required this.trustScore,
    required this.ownerUserId,
    required this.categories,
    required this.location,
    required this.pitch,
    this.websiteUrl = '',
    this.avatarUrl,
  });

  factory StoreBadgeModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final categoriesList = rawCats is List ? rawCats : const <dynamic>[];
    final locationRaw = json['location'];

    StoreLocation? loc;
    if (locationRaw is Map) {
      try {
        final m = Map<String, dynamic>.from(locationRaw);
        loc = StoreLocation.fromJson(m);
      } catch (_) {
        loc = null;
      }
    }

    return StoreBadgeModel(
      id: (json['id'] as Object?)?.toString() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      verified: (json['verified'] as bool?) ?? false,
      transportIncluded: (json['transportIncluded'] as bool?) ?? false,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 0,
      ownerUserId: (json['ownerUserId'] as Object?)?.toString() ?? '',
      categories: categoriesList
          .map((e) => e?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      location: loc?.looksValid == true ? loc : null,
      pitch: (json['pitch'] as String?)?.trim() ?? '',
      websiteUrl: (json['websiteUrl'] as String?)?.trim() ?? '',
      avatarUrl: _pickAvatarUrl(json),
    );
  }

  /// `MarketCatalogStoreBadgeJson` usa `avatarUrl`; mantenemos alias por compat.
  static String? _pickAvatarUrl(Map<String, dynamic> json) {
    const keys = [
      'avatarUrl',
      'logoUrl',
      'logo',
      'imageUrl',
      'brandLogo',
      'brandLogoUrl',
      'storeLogo',
      'thumbnailUrl',
      'coverImageUrl',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is String) {
        final t = value.trim();
        if (t.isNotEmpty) return t;
      }
    }
    return null;
  }
}
