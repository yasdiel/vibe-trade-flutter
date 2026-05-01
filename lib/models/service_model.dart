import 'package:vibe_trade_v1/models/product_model.dart';

class ServiceModel {
  final String id;
  final String storeId;
  final String category;
  final String serviceType;
  final List<ProductCurrency> acceptedCurrencies;
  final String description;

  // Riesgos opcionales (se persisten solo si el toggle esta activo).
  final bool hasRisks;
  final String risks;

  final String includes;
  final String excludes;

  // Dependencias opcionales.
  final bool hasDependencies;
  final String dependencies;

  final String delivery;

  // Garantias opcionales.
  final bool hasWarranty;
  final String warranty;

  final String intellectualProperty;

  // El servicio admite multiples fotos (minimo 1).
  final List<String> imagePaths;

  final DateTime createdAt;

  const ServiceModel({
    required this.id,
    required this.storeId,
    required this.category,
    required this.serviceType,
    required this.acceptedCurrencies,
    required this.description,
    required this.hasRisks,
    required this.risks,
    required this.includes,
    required this.excludes,
    required this.hasDependencies,
    required this.dependencies,
    required this.delivery,
    required this.hasWarranty,
    required this.warranty,
    required this.intellectualProperty,
    required this.imagePaths,
    required this.createdAt,
  });

  ServiceModel copyWith({
    String? category,
    String? serviceType,
    List<ProductCurrency>? acceptedCurrencies,
    String? description,
    bool? hasRisks,
    String? risks,
    String? includes,
    String? excludes,
    bool? hasDependencies,
    String? dependencies,
    String? delivery,
    bool? hasWarranty,
    String? warranty,
    String? intellectualProperty,
    List<String>? imagePaths,
    DateTime? createdAt,
  }) {
    return ServiceModel(
      id: id,
      storeId: storeId,
      category: category ?? this.category,
      serviceType: serviceType ?? this.serviceType,
      acceptedCurrencies: acceptedCurrencies ?? this.acceptedCurrencies,
      description: description ?? this.description,
      hasRisks: hasRisks ?? this.hasRisks,
      risks: risks ?? this.risks,
      includes: includes ?? this.includes,
      excludes: excludes ?? this.excludes,
      hasDependencies: hasDependencies ?? this.hasDependencies,
      dependencies: dependencies ?? this.dependencies,
      delivery: delivery ?? this.delivery,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      warranty: warranty ?? this.warranty,
      intellectualProperty: intellectualProperty ?? this.intellectualProperty,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'category': category,
      'serviceType': serviceType,
      'acceptedCurrencies':
          acceptedCurrencies.map((c) => c.value).toList(),
      'description': description,
      'hasRisks': hasRisks,
      'risks': risks,
      'includes': includes,
      'excludes': excludes,
      'hasDependencies': hasDependencies,
      'dependencies': dependencies,
      'delivery': delivery,
      'hasWarranty': hasWarranty,
      'warranty': warranty,
      'intellectualProperty': intellectualProperty,
      'imagePaths': imagePaths,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawCurrencies = (json['acceptedCurrencies'] as List?) ?? const [];
    final rawImages = (json['imagePaths'] as List?) ?? const [];
    return ServiceModel(
      id: (json['id'] as String?) ?? '',
      storeId: (json['storeId'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      serviceType: (json['serviceType'] as String?) ?? '',
      acceptedCurrencies: rawCurrencies
          .whereType<String>()
          .map(ProductCurrency.fromValue)
          .whereType<ProductCurrency>()
          .toList(growable: false),
      description: (json['description'] as String?) ?? '',
      hasRisks: (json['hasRisks'] as bool?) ?? false,
      risks: (json['risks'] as String?) ?? '',
      includes: (json['includes'] as String?) ?? '',
      excludes: (json['excludes'] as String?) ?? '',
      hasDependencies: (json['hasDependencies'] as bool?) ?? false,
      dependencies: (json['dependencies'] as String?) ?? '',
      delivery: (json['delivery'] as String?) ?? '',
      hasWarranty: (json['hasWarranty'] as bool?) ?? false,
      warranty: (json['warranty'] as String?) ?? '',
      intellectualProperty:
          (json['intellectualProperty'] as String?) ?? '',
      imagePaths: rawImages.whereType<String>().toList(growable: false),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
