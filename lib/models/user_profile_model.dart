class UserProfileModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String imageUrl;
  final String instagram;
  final String xHandle;
  final String telegram;
  final int? trustScore;

  const UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.imageUrl,
    required this.instagram,
    required this.xHandle,
    required this.telegram,
    this.trustScore,
  });

  static const empty = UserProfileModel(
    id: '',
    name: '',
    email: '',
    phone: '',
    imageUrl: '',
    instagram: '',
    xHandle: '',
    telegram: '',
  );

  bool get isEmpty =>
      id.isEmpty &&
      name.isEmpty &&
      email.isEmpty &&
      phone.isEmpty &&
      imageUrl.isEmpty &&
      instagram.isEmpty &&
      xHandle.isEmpty &&
      telegram.isEmpty &&
      trustScore == null;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: _pickString(json, const [
        'id',
        'userId',
        'user_id',
        'profileId',
        'profile_id',
        '_id',
        'uid',
      ]),
      name: _pickString(json, const [
        'name',
        'fullName',
        'fullname',
        'displayName',
        'username',
        'userName',
      ]),
      email: _pickString(json, const ['email', 'mail']),
      phone: _pickString(json, const [
        'phone',
        'phoneNumber',
        'mobile',
        'mobileNumber',
      ]),
      imageUrl: _pickString(json, const [
        'image',
        'imageUrl',
        'avatar',
        'avatarUrl',
        'photo',
        'photoUrl',
        'profileImage',
        'profileImageUrl',
      ]),
      instagram: _pickString(json, const [
        'instagram',
        'instagramUser',
        'instagramUsername',
        'instagramUrl',
      ]),
      xHandle: _pickString(json, const [
        'x',
        'xHandle',
        'twitter',
        'twitterHandle',
        'twitterUsername',
        'xUsername',
      ]),
      telegram: _pickString(json, const [
        'telegram',
        'telegramUser',
        'telegramUsername',
        'telegramUrl',
      ]),
      trustScore: _pickInt(json, const [
        'trustScore',
        'trust_score',
        'trust',
        'trustLevel',
        'trust_level',
        'confidence',
        'confidenceScore',
        'confidence_score',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'instagram': instagram,
      'xHandle': xHandle,
      'telegram': telegram,
      if (trustScore != null) 'trustScore': trustScore,
    };
  }

  static String _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final direct = json[key];
      if (direct is String && direct.trim().isNotEmpty) {
        return direct.trim();
      }
    }

    for (final value in json.values) {
      if (value is Map) {
        final nested = _pickString(Map<String, dynamic>.from(value), keys);
        if (nested.isNotEmpty) {
          return nested;
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final nested = _pickString(Map<String, dynamic>.from(item), keys);
            if (nested.isNotEmpty) {
              return nested;
            }
          }
        }
      }
    }

    return '';
  }

  static int? _pickInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final direct = json[key];
      final parsed = _parseInt(direct);
      if (parsed != null) {
        return parsed.clamp(0, 100);
      }
    }

    for (final value in json.values) {
      if (value is Map) {
        final nested = _pickInt(Map<String, dynamic>.from(value), keys);
        if (nested != null) return nested;
      } else if (value is List) {
        for (final item in value) {
          if (item is Map) {
            final nested = _pickInt(Map<String, dynamic>.from(item), keys);
            if (nested != null) return nested;
          }
        }
      }
    }

    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
