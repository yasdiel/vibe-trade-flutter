import 'dart:io' show Platform, Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.vibetrade/external_url');

/// Abre una URL http(s) en el navegador del sistema sin depender de pub.dev.
Future<bool> launchExternalUrl(String url) async {
  if (kIsWeb) return false;

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final ok = await _channel.invokeMethod<bool>('launch', {'url': url});
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  try {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
      return true;
    }
    if (Platform.isMacOS) {
      await Process.run('open', [url]);
      return true;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
      return true;
    }
  } catch (_) {
    return false;
  }
  return false;
}
