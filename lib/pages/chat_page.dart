import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:vibe_trade_v1/pages/chat_thread_page.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/chat_service.dart';
import 'package:vibe_trade_v1/services/main_tab_bus.dart';
import 'package:vibe_trade_v1/services/session_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Pestaña de chats. Equivalente al `ChatListPage` del demo en React
/// (`src/pages/chat/ChatListPage.tsx`):
/// - Lista de hilos del usuario actual desde `GET /api/v1/chat/threads`.
/// - Buscador por título / tienda / vista previa.
/// - Estado vacío que invita a comprar desde una oferta.
/// - Tap → `ChatThreadPage`; long-press / botón → eliminar hilo.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  List<_ChatRow> _rows = const <_ChatRow>[];
  bool _loading = true;
  String? _error;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SessionService.isLoggedInNotifier.addListener(_onSessionChanged);
    _loadThreads();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionService.isLoggedInNotifier.removeListener(_onSessionChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadThreads(silent: true);
    }
  }

  void _onSessionChanged() {
    if (!mounted) return;
    if (!SessionService.isLoggedInNotifier.value) {
      setState(() {
        _rows = const <_ChatRow>[];
        _loading = false;
        _error = null;
      });
    } else {
      _loadThreads();
    }
  }

  Future<void> _loadThreads({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await ChatService.fetchChatThreads();
      if (!mounted) return;
      final parsed = list.map(_ChatRow.fromJson).toList(growable: false);
      parsed.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
      setState(() {
        _rows = parsed;
        _loading = false;
      });
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _rows = const <_ChatRow>[];
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

  Future<void> _openThread(_ChatRow row) async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadPage(
          threadId: row.id,
          storeName: row.title,
        ),
      ),
    );
    if (!mounted) return;
    await _loadThreads(silent: true);
  }

  Future<void> _confirmDelete(_ChatRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir del chat'),
        content: Text(
          '¿Seguro que quieres quitar «${row.title}» de tu lista de chats?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ChatService.deleteChatThread(row.id);
      if (!mounted) return;
      setState(() {
        _rows = _rows.where((r) => r.id != row.id).toList(growable: false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
      ));
    }
  }

  List<_ChatRow> get _filteredRows {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    final needle = _normalize(q);
    return _rows.where((r) {
      final hay = _normalize(
        '${r.title} ${r.preview} ${r.id}',
      );
      return hay.contains(needle);
    }).toList(growable: false);
  }

  static String _normalize(String s) {
    final lowered = s.toLowerCase();
    const map = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
      'ü': 'u',
    };
    final buf = StringBuffer();
    for (final ch in lowered.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!SessionService.isLoggedInNotifier.value) {
      return _buildLoggedOut();
    }
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => _loadThreads(silent: true),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Row(
          children: [
            Text(
              'Chats',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const Spacer(),
            if (_rows.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.selectedColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_rows.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Nombre, tienda…',
            prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 18),
            filled: true,
            fillColor: AppTheme.foregroundColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          )
        else if (_error != null)
          _ErrorState(message: _error!, onRetry: _loadThreads)
        else if (_rows.isEmpty)
          const _EmptyChatsState()
        else if (_filteredRows.isEmpty)
          _NoMatchesState(
            query: _query,
            onClear: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.foregroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _filteredRows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AppTheme.dividerColor,
                      indent: 12,
                      endIndent: 12,
                    ),
                  _ChatRowTile(
                    row: _filteredRows[i],
                    onTap: () => _openThread(_filteredRows[i]),
                    onDelete: () => _confirmDelete(_filteredRows[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoggedOut() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Inicia sesión para ver tus chats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando entres a tu cuenta podrás abrir conversaciones desde el botón «Comprar» de cualquier oferta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/signin'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Iniciar sesión'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRow {
  final String id;
  final String title;
  final String preview;
  final int lastActivity;
  final bool purchaseMode;
  final bool isSocialGroup;

  const _ChatRow({
    required this.id,
    required this.title,
    required this.preview,
    required this.lastActivity,
    required this.purchaseMode,
    required this.isSocialGroup,
  });

  String get avatarLetter {
    final t = title.trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }

  factory _ChatRow.fromJson(Map<String, dynamic> json) {
    String pickStr(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    final id = pickStr(const ['id', 'Id']);
    final isSocial = (json['isSocialGroup'] ?? json['IsSocialGroup']) == true;
    final social = pickStr(const ['socialGroupTitle', 'SocialGroupTitle']);
    final buyer = pickStr(const ['buyerDisplayName', 'BuyerDisplayName']);
    final lastPreview = pickStr(const ['lastPreview', 'LastPreview']);
    final lastAtRaw = json['lastMessageAtUtc'] ?? json['LastMessageAtUtc'];
    final createdAtRaw = json['createdAtUtc'] ?? json['CreatedAtUtc'];

    int parseEpochMs(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String && value.trim().isNotEmpty) {
        final dt = DateTime.tryParse(value.trim());
        if (dt != null) return dt.millisecondsSinceEpoch;
      }
      return 0;
    }

    final at = parseEpochMs(lastAtRaw);
    final createdAt = parseEpochMs(createdAtRaw);

    var title = '';
    if (isSocial && social.isNotEmpty) {
      title = social;
    } else if (buyer.isNotEmpty) {
      title = buyer;
    } else {
      title = pickStr(const ['storeId', 'StoreId']);
    }
    if (title.isEmpty) title = 'Chat';

    return _ChatRow(
      id: id,
      title: title,
      preview: lastPreview.isNotEmpty ? lastPreview : 'Sin mensajes',
      lastActivity: at > 0 ? at : createdAt,
      purchaseMode: (json['purchaseMode'] ?? json['PurchaseMode']) == true,
      isSocialGroup: isSocial,
    );
  }
}

class _ChatRowTile extends StatelessWidget {
  final _ChatRow row;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatRowTile({
    required this.row,
    required this.onTap,
    required this.onDelete,
  });

  String _fmtShort(int ts) {
    if (ts <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    final sameDay =
        d.year == now.year && d.month == now.month && d.day == now.day;
    if (sameDay) {
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.selectedColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  row.avatarLetter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _fmtShort(row.lastActivity),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Salir',
                onPressed: onDelete,
                icon: Icon(
                  Icons.logout_outlined,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatsState extends StatelessWidget {
  const _EmptyChatsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no tienes conversaciones',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Abre una oferta y toca «Comprar» para iniciar un chat con la tienda.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => MainTabBus.selectTab?.call(0),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Ver ofertas'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _NoMatchesState({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 8),
          Text(
            'No hay chats que coincidan con «${query.trim()}».',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onClear,
            child: const Text('Quitar filtro'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function({bool silent}) onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// Evita warning si en algún build futuro se necesita serializar.
// ignore: unused_element
String _toJsonForLog(Object? v) => jsonEncode(v);
