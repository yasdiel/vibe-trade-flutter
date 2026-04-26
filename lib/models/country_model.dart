class CountryModel {
  final String name;
  final String code;
  final String dial;
  final String flag;

  CountryModel({
    required this.name,
    required this.code,
    required this.dial,
    required this.flag,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
    name: json['name'] as String? ?? '',
    code: json['code'] as String? ?? '',
    dial: json['dial'] as String? ?? '',
    flag: json['flag'] as String? ?? '',
  );
}
