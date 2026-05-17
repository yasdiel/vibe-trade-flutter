import 'dart:async';

import 'package:flutter/material.dart';

import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/chat_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Pantalla de un hilo de chat. Usa los endpoints:
/// - `GET  /api/v1/chat/threads/{id}/messages`
/// - `POST /api/v1/chat/threads/{id}/messages`
///
/// El payload sigue el shape `ChatMessageDto` (camelCase) del backend:
/// `{ id, threadId, senderUserId, payload: { type, text, ... }, status,
///   createdAtUtc, updatedAtUtc, senderDisplayLabel? }`.
class ChatThreadPage extends StatefulWidget {
  final String threadId;
  final String storeName;

  const ChatThreadPage({
    super.key,
    required this.threadId,
    this.storeName = '',
  });

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  List<_ChatMessage> _messages = const <_ChatMessage>[];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  final TextEditingController _draftCtrl = TextEditingController();
  final FocusNode _draftFocus = FocusNode();
  final ScrollController _listCtrl = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _draftCtrl.dispose();
    _draftFocus.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final raw = await ChatService.fetchChatMessages(widget.threadId);
      final parsed = raw.map(_ChatMessage.fromJson).toList(growable: false);
      parsed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      if (!mounted) return;
      setState(() {
        _messages = parsed;
        _loading = false;
      });
      _jumpToBottom();
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Tu sesión expiró. Inicia sesión nuevamente.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listCtrl.hasClients) return;
      _listCtrl.animateTo(
        _listCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _draftCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ChatService.postChatTextMessage(widget.threadId, text);
      if (!mounted) return;
      _draftCtrl.clear();
      await _load(silent: true);
      _draftFocus.requestFocus();
    } on UnauthorizedException {
      _toast('Tu sesión expiró. Inicia sesión nuevamente.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.storeName.trim().isNotEmpty
        ? widget.storeName.trim()
        : 'Chat';

    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.foregroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refrescar',
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _messages.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_error != null && _messages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no hay mensajes en este hilo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Escribe el primer mensaje para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    final me = SessionService.currentUserNotifier.value;
    final myId = (me?.id ?? '').trim();

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => _load(silent: true),
      child: ListView.separated(
        controller: _listCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final m = _messages[i];
          final mine = myId.isNotEmpty && m.senderUserId == myId;
          return _MessageBubble(message: m, isMine: mine);
        },
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _draftCtrl,
              focusNode: _draftFocus,
              enabled: !_sending,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.inputFillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppTheme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppTheme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide:
                      BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: AppTheme.primaryColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sending ? null : _send,
                child: Center(
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String threadId;
  final String senderUserId;
  final String? senderDisplayLabel;
  final String type;
  final String? text;
  final String? caption;
  final List<String> imageUrls;
  final int createdAt;
  final String status;

  const _ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.senderDisplayLabel,
    required this.type,
    required this.text,
    required this.caption,
    required this.imageUrls,
    required this.createdAt,
    required this.status,
  });

  /// Texto a renderizar en la burbuja según el tipo (text, image, audio, …).
  String previewText() {
    final t = (text ?? '').trim();
    final c = (caption ?? '').trim();
    if (type == 'text' && t.isNotEmpty) return t;
    if (type == 'image') {
      if (c.isNotEmpty) return c;
      if (imageUrls.isNotEmpty) return '(Imagen)';
    }
    if (type.isEmpty) return t.isNotEmpty ? t : '(Mensaje)';
    return '[$type]';
  }

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    String pickStr(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    final id = pickStr(const ['id', 'Id']);
    final threadId = pickStr(const ['threadId', 'ThreadId']);
    final senderUserId = pickStr(const ['senderUserId', 'SenderUserId']);
    final senderLabelRaw =
        pickStr(const ['senderDisplayLabel', 'SenderDisplayLabel']);
    final status = pickStr(const ['status', 'Status']);

    final createdRaw = json['createdAtUtc'] ?? json['CreatedAtUtc'];
    int createdAt = 0;
    if (createdRaw is num) {
      createdAt = createdRaw.toInt();
    } else if (createdRaw is String && createdRaw.trim().isNotEmpty) {
      final dt = DateTime.tryParse(createdRaw.trim());
      if (dt != null) createdAt = dt.millisecondsSinceEpoch;
    }

    final payloadRaw = json['payload'] ?? json['Payload'];
    final payload = payloadRaw is Map
        ? Map<String, dynamic>.from(payloadRaw)
        : <String, dynamic>{};

    final type =
        ((payload['type'] ?? payload['Type'])?.toString() ?? '').trim();
    final text = (payload['text'] ?? payload['Text'])?.toString();
    final caption =
        (payload['caption'] ?? payload['Caption'])?.toString();
    final imagesRaw = payload['images'] ?? payload['Images'];
    final imageUrls = <String>[];
    if (imagesRaw is List) {
      for (final entry in imagesRaw) {
        if (entry is Map) {
          final url = (entry['url'] ?? entry['Url'])?.toString();
          if (url != null && url.trim().isNotEmpty) imageUrls.add(url.trim());
        } else if (entry is String && entry.trim().isNotEmpty) {
          imageUrls.add(entry.trim());
        }
      }
    }

    return _ChatMessage(
      id: id,
      threadId: threadId,
      senderUserId: senderUserId,
      senderDisplayLabel: senderLabelRaw.isEmpty ? null : senderLabelRaw,
      type: type,
      text: text,
      caption: caption,
      imageUrls: List<String>.unmodifiable(imageUrls),
      createdAt: createdAt,
      status: status,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  String _hhmm(int ts) {
    if (ts <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final preview = message.previewText();
    final hasLabel = !isMine &&
        (message.senderDisplayLabel ?? '').trim().isNotEmpty;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      decoration: BoxDecoration(
        color: isMine
            ? AppTheme.primaryColor
            : AppTheme.foregroundColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: const Radius.circular(14),
          bottomLeft: Radius.circular(isMine ? 14 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 14),
        ),
        border: Border.all(
          color: isMine ? AppTheme.primaryColor : AppTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLabel)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.senderDisplayLabel!.trim(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          Text(
            preview,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: isMine ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _hhmm(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppTheme.textMuted,
                ),
              ),
              if (isMine && message.status.isNotEmpty) ...[
                const SizedBox(width: 4),
                Icon(
                  message.status == 'read'
                      ? Icons.done_all
                      : Icons.done,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [bubble],
    );
  }
}
