import 'package:dotenv/dotenv.dart';

final env = DotEnv(includePlatformEnvironment: true);

String get baseUrl {
  final value = env['baseUrl']?.trim();
  if (value == null || value.isEmpty) {
    throw StateError('La variable de entorno baseUrl no esta configurada.');
  }
  return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
