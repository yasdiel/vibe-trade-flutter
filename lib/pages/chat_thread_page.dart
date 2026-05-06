import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/chat_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Pantalla de un hilo de chat tras "Comprar (Chat)". Lista mensajes desde la API;
/// el UI completo puede evolucionar como en el demo web.
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
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ChatService.fetchChatMessages(widget.threadId);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  static String? _previewLine(Map<String, dynamic> m) {
    final payload = m['payload'];
    if (payload is! Map) return null;
    final p = Map<String, dynamic>.from(payload);
    final type = (p['type'] ?? '').toString();
    if (type == 'text') {
      return (p['text'] ?? '').toString().trim();
    }
    if (type == 'image') {
      final cap = (p['caption'] ?? '').toString().trim();
      return cap.isEmpty ? '(Imagen)' : cap;
    }
    if (type.isEmpty) return null;
    return '[$type]';
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
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.25,
          ),
          Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ],
      );
    }
    if (_error != null && _messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 40),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }
    if (_messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Aún no hay mensajes en este hilo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _messages.length,
      separatorBuilder: (context, i) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = _messages[i];
        final line = _previewLine(m) ?? 'Mensaje';
        final label = (m['senderDisplayLabel'] ?? '')
            .toString()
            .trim();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.foregroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              if (label.isNotEmpty) const SizedBox(height: 4),
              Text(
                line,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
