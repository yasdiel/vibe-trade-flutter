enum ProductCondition {
  brandNew,
  used,
  refurbished;

  static ProductCondition? fromValue(String? value) {
    switch (value) {
      case 'new':
        return ProductCondition.brandNew;
      case 'used':
        return ProductCondition.used;
      case 'refurbished':
        return ProductCondition.refurbished;
      default:
        return null;
    }
  }

  String get value {
    switch (this) {
      case ProductCondition.brandNew:
        return 'new';
      case ProductCondition.used:
        return 'used';
      case ProductCondition.refurbished:
        return 'refurbished';
    }
  }

  String get label {
    switch (this) {
      case ProductCondition.brandNew:
        return 'Nuevo';
      case ProductCondition.used:
        return 'Usado';
      case ProductCondition.refurbished:
        return 'Reacondicionado';
    }
  }
}

enum ProductCurrency {
  eur,
  cup,
  usd;

  static const allValues = [eur, cup, usd];

  static ProductCurrency? fromValue(String? value) {
    switch (value) {
      case 'EUR':
        return ProductCurrency.eur;
      case 'CUP':
        return ProductCurrency.cup;
      case 'USD':
        return ProductCurrency.usd;
      default:
        return null;
    }
  }

  String get value {
    switch (this) {
      case ProductCurrency.eur:
        return 'EUR';
      case ProductCurrency.cup:
        return 'CUP';
      case ProductCurrency.usd:
        return 'USD';
    }
  }

  String get label {
    switch (this) {
      case ProductCurrency.eur:
        return 'Euro (EUR)';
      case ProductCurrency.cup:
        return 'Peso cubano (CUP)';
      case ProductCurrency.usd:
        return 'Dolar (USD)';
    }
  }

  String get symbol {
    switch (this) {
      case ProductCurrency.eur:
        return '€';
      case ProductCurrency.cup:
        return '\$';
      case ProductCurrency.usd:
        return 'US\$';
    }
  }
}

class ProductModel {
  final String id;
  final String storeId;
  final String name;
  final String category;
  final String version;
  final double price;
  final ProductCurrency? priceCurrency;
  final ProductCondition? condition;
  final List<ProductCurrency> acceptedCurrencies;
  final String description;
  final String mainBenefit;
  final String technicalFeatures;
  final String imagePath;
  final DateTime createdAt;

  // Datos comerciales opcionales adicionales.
  final String taxesShippingInstall;
  final int? stock;
  final String warrantyAndReturns;
  final String includedContent;
  final String usageConditions;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.version,
    required this.price,
    required this.priceCurrency,
    required this.condition,
    required this.acceptedCurrencies,
    required this.description,
    required this.mainBenefit,
    required this.technicalFeatures,
    required this.imagePath,
    required this.createdAt,
    this.taxesShippingInstall = '',
    this.stock,
    this.warrantyAndReturns = '',
    this.includedContent = '',
    this.usageConditions = '',
  });

  ProductModel copyWith({
    String? name,
    String? category,
    String? version,
    double? price,
    ProductCurrency? priceCurrency,
    ProductCondition? condition,
    List<ProductCurrency>? acceptedCurrencies,
    String? description,
    String? mainBenefit,
    String? technicalFeatures,
    String? imagePath,
    DateTime? createdAt,
    String? taxesShippingInstall,
    Object? stock = _kCopyUnset,
    String? warrantyAndReturns,
    String? includedContent,
    String? usageConditions,
  }) {
    return ProductModel(
      id: id,
      storeId: storeId,
      name: name ?? this.name,
      category: category ?? this.category,
      version: version ?? this.version,
      price: price ?? this.price,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      condition: condition ?? this.condition,
      acceptedCurrencies: acceptedCurrencies ?? this.acceptedCurrencies,
      description: description ?? this.description,
      mainBenefit: mainBenefit ?? this.mainBenefit,
      technicalFeatures: technicalFeatures ?? this.technicalFeatures,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      taxesShippingInstall:
          taxesShippingInstall ?? this.taxesShippingInstall,
      stock: identical(stock, _kCopyUnset) ? this.stock : stock as int?,
      warrantyAndReturns: warrantyAndReturns ?? this.warrantyAndReturns,
      includedContent: includedContent ?? this.includedContent,
      usageConditions: usageConditions ?? this.usageConditions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'name': name,
      'category': category,
      'version': version,
      'price': price,
      'priceCurrency': priceCurrency?.value,
      'condition': condition?.value,
      'acceptedCurrencies':
          acceptedCurrencies.map((c) => c.value).toList(),
      'description': description,
      'mainBenefit': mainBenefit,
      'technicalFeatures': technicalFeatures,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'taxesShippingInstall': taxesShippingInstall,
      'stock': stock,
      'warrantyAndReturns': warrantyAndReturns,
      'includedContent': includedContent,
      'usageConditions': usageConditions,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawCurrencies = (json['acceptedCurrencies'] as List?) ?? const [];
    return ProductModel(
      id: (json['id'] as String?) ?? '',
      storeId: (json['storeId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceCurrency: ProductCurrency.fromValue(
        json['priceCurrency'] as String?,
      ),
      condition: ProductCondition.fromValue(json['condition'] as String?),
      acceptedCurrencies: rawCurrencies
          .whereType<String>()
          .map(ProductCurrency.fromValue)
          .whereType<ProductCurrency>()
          .toList(growable: false),
      description: (json['description'] as String?) ?? '',
      mainBenefit: (json['mainBenefit'] as String?) ?? '',
      technicalFeatures: (json['technicalFeatures'] as String?) ?? '',
      imagePath: (json['imagePath'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      taxesShippingInstall:
          (json['taxesShippingInstall'] as String?) ?? '',
      stock: (json['stock'] as num?)?.toInt(),
      warrantyAndReturns: (json['warrantyAndReturns'] as String?) ?? '',
      includedContent: (json['includedContent'] as String?) ?? '',
      usageConditions: (json['usageConditions'] as String?) ?? '',
    );
  }
}

const Object _kCopyUnset = Object();
