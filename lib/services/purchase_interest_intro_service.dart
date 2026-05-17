import 'package:http/http.dart' as http;
import 'package:vibe_trade_v1/models/offer_model.dart';
import 'package:vibe_trade_v1/services/chat_service.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';
import 'package:vibe_trade_v1/utils/image_upload_limits.dart';
import 'package:vibe_trade_v1/utils/tool_placeholder_url.dart';

enum CatalogItemKind { product, service, unknown }

CatalogItemKind catalogItemKind(OfferModel offer) {
  if (offer.isService) return CatalogItemKind.service;
  if (offer.isProduct) return CatalogItemKind.product;
  return CatalogItemKind.unknown;
}

/// URLs de ficha sin duplicar ni placeholders (orden estable).
List<String> collectOfferPublishedPhotoUrls(OfferModel offer) {
  final out = <String>[];
  final seen = <String>{};
  final raw = <String>[
    if ((offer.imageUrl ?? '').trim().isNotEmpty) offer.imageUrl!.trim(),
    ...offer.imageUrls,
  ];
  for (final u in raw) {
    final t = u.trim();
    if (t.isEmpty || isToolPlaceholderUrl(t)) continue;
    if (seen.contains(t)) continue;
    seen.add(t);
    out.add(t);
  }
  return out;
}

String buildPurchaseIntroCaption(
  OfferModel offer,
  CatalogItemKind kind,
  bool hasRealPhotos,
) {
  final rawTitle = offer.title.trim();
  final book = rawTitle.isNotEmpty ? '«$rawTitle»' : 'esta oferta';
  switch (kind) {
    case CatalogItemKind.product:
      if (hasRealPhotos) {
        return 'Hola, tengo interés en el producto $book. Vi las fotos publicadas en la ficha y me gustaría coordinar contigo.';
      }
      return 'Hola, tengo interés en el producto $book. Quiero charlar contigo para avanzar con la compra.';
    case CatalogItemKind.service:
      if (hasRealPhotos) {
        return 'Hola, tengo interés en el servicio $book. Vi las imágenes de la ficha y me gustaría coordinar contigo.';
      }
      return 'Hola, tengo interés en el servicio $book. Me gustaría charlar contigo para avanzar.';
    case CatalogItemKind.unknown:
      if (hasRealPhotos) {
        return 'Hola, tengo interés en la oferta $book. Comparto referencia de la ficha y me gustaría charlar contigo.';
      }
      return 'Hola, tengo interés en la oferta $book. Quiero abrir un canal contigo para charlarlo.';
  }
}

Future<String?> _publicImageUrlToMediaRef(String publicUrl, int i) async {
  try {
    final resolved = MediaService.resolveMediaUrl(publicUrl);
    final token = await SessionService.getSavedToken();
    final headers = <String, String>{'Accept': '*/*'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = SessionService.buildAuthorizationHeader(token);
    }
    final res = await http.get(Uri.parse(resolved), headers: headers);
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    final bytes = res.bodyBytes;
    if (bytes.isEmpty) return null;
    if (imageBytesSizeError(bytes) != null) return null;
    var ext = 'jpg';
    final ct = res.headers['content-type'] ?? '';
    if (ct.contains('png')) {
      ext = 'png';
    } else if (ct.contains('webp')) {
      ext = 'webp';
    }
    return MediaService.uploadImageBytes(
      bytes: bytes,
      filename: 'oferta_ficha_$i.$ext',
    );
  } catch (_) {
    return null;
  }
}

/// Primer mensaje al pulsar "Comprar (Chat)" (texto o imagen+caption), como en React.
Future<void> sendPurchaseInterestIntro(
  String threadId,
  OfferModel offer,
) async {
  if (!threadId.startsWith('cth_')) {
    throw StateError('thread_not_persisted');
  }
  final kind = catalogItemKind(offer);
  final publicUrls = collectOfferPublishedPhotoUrls(offer);
  final hasRealPhotos = publicUrls.isNotEmpty;
  final caption = buildPurchaseIntroCaption(offer, kind, hasRealPhotos);

  if (publicUrls.isEmpty) {
    await ChatService.postChatTextMessage(threadId, caption);
    return;
  }

  final uploaded = <Map<String, String>>[];
  for (var j = 0; j < publicUrls.length; j++) {
    final mediaPath = await _publicImageUrlToMediaRef(publicUrls[j], j);
    if (mediaPath != null && mediaPath.isNotEmpty) {
      uploaded.add({'url': MediaService.resolveMediaUrl(mediaPath)});
    }
  }

  if (uploaded.isEmpty) {
    await ChatService.postChatTextMessage(threadId, caption);
    return;
  }

  await ChatService.postChatMessage(threadId, {
    'type': 'image',
    'images': uploaded,
    'caption': caption,
  });
}
