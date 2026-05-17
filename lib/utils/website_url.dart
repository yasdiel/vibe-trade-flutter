import 'package:vibe_trade_v1/utils/external_url_launcher.dart';

/// Normaliza URL de sitio. Vacío → null. Sin esquema → https.
String? normalizeOwnerWebsiteUrl(String? raw) {
  final t = (raw ?? '').trim();
  if (t.isEmpty) return null;
  var u = t;
  if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(u)) {
    u = 'https://$u';
  }
  try {
    final parsed = Uri.parse(u);
    if (parsed.scheme != 'http' && parsed.scheme != 'https') return null;
    if (parsed.host.isEmpty) return null;
    return parsed.toString();
  } catch (_) {
    return null;
  }
}

/// Etiqueta corta para UI (host + path resumido).
String websiteUrlDisplayLabel(String href) {
  try {
    final u = Uri.parse(href);
    var host = u.host;
    if (host.startsWith('www.')) {
      host = host.substring(4);
    }
    final path = u.path.isNotEmpty && u.path != '/' ? u.path : '';
    final s = '$host$path';
    if (s.length > 42) return '${s.substring(0, 39)}…';
    return s;
  } catch (_) {
    return href;
  }
}

Future<bool> launchWebsiteUrl(String raw) async {
  final normalized = normalizeOwnerWebsiteUrl(raw);
  if (normalized == null) return false;
  return launchExternalUrl(normalized);
}
