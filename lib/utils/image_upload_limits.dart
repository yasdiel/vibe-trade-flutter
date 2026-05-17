import 'dart:io';

/// Tamano maximo permitido para subir fotos (5 MB).
const int kMaxImageUploadBytes = 5 * 1024 * 1024;

const String kMaxImageUploadSizeMessage =
    'La imagen no puede superar 5 MB. Elige otra mas liviana.';

/// Devuelve mensaje de error si el archivo no es valido para subir; si no, `null`.
Future<String?> imageFileSizeError(File file) async {
  if (!await file.exists()) {
    return 'El archivo de imagen no existe.';
  }
  final length = await file.length();
  if (length == 0) {
    return 'El archivo de imagen esta vacio.';
  }
  if (length > kMaxImageUploadBytes) {
    return kMaxImageUploadSizeMessage;
  }
  return null;
}

/// Devuelve mensaje de error si los bytes no son validos para subir; si no, `null`.
String? imageBytesSizeError(List<int> bytes) {
  if (bytes.isEmpty) {
    return 'La imagen esta vacia.';
  }
  if (bytes.length > kMaxImageUploadBytes) {
    return kMaxImageUploadSizeMessage;
  }
  return null;
}

Future<void> assertImageFileUploadable(File file) async {
  final error = await imageFileSizeError(file);
  if (error != null) {
    throw Exception(error);
  }
}

void assertImageBytesUploadable(List<int> bytes) {
  final error = imageBytesSizeError(bytes);
  if (error != null) {
    throw Exception(error);
  }
}
