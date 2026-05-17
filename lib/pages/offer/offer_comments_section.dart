import 'package:flutter/material.dart';

import 'package:vibe_trade_v1/models/offer_comment_model.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/pages/offer/offer_comments_widgets.dart';
import 'package:vibe_trade_v1/services/auth_exceptions.dart';
import 'package:vibe_trade_v1/services/offer_comments_service.dart';
import 'package:vibe_trade_v1/services/session_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Sección "Comentarios públicos" del detalle de oferta. Equivalente al
/// `OfferCommentsSection` del demo en React (`src/pages/offer/OfferCommentsSection.tsx`).
///
/// Encadena los tres endpoints implementados en `OfferCommentsService`:
/// - `GET /Market/offers/{id}/qa` para hidratar y refrescar.
/// - `POST /Market/inquiries` para publicar un comentario o respuesta.
/// - `POST /Market/offers/{id}/qa/{qaId}/like` para alternar el me gusta.
class OfferCommentsSection extends StatefulWidget {
  final String offerId;

  /// `ownerUserId` de la tienda dueña; se usa para identificar comentarios
  /// del vendedor y para bloquear que abra hilos en su propia ficha (sólo
  /// puede responder a comentarios de terceros).
  final String? storeOwnerUserId;

  /// Notifica al padre si el conteo de comentarios cambió, para que pueda
  /// refrescar contadores externos (e.g. el chip junto al like).
  final ValueChanged<int>? onCommentCountChanged;

  const OfferCommentsSection({
    super.key,
    required this.offerId,
    this.storeOwnerUserId,
    this.onCommentCountChanged,
  });

  @override
  State<OfferCommentsSection> createState() => _OfferCommentsSectionState();
}

class _OfferCommentsSectionState extends State<OfferCommentsSection> {
  final TextEditingController _draftCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _listCtrl = ScrollController();

  List<OfferCommentNorm> _comments = const <OfferCommentNorm>[];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  OfferCommentNorm? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _draftCtrl.dispose();
    _inputFocus.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await OfferCommentsService.fetchOfferComments(widget.offerId);
      if (!mounted) return;
      setState(() {
        _comments = list;
        _loading = false;
      });
      widget.onCommentCountChanged?.call(_topLevelCount(list));
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _comments = const <OfferCommentNorm>[];
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

  int _topLevelCount(List<OfferCommentNorm> list) =>
      list.where((c) => c.parentId == null).length;

  bool get _isOwnOffer {
    final owner = widget.storeOwnerUserId?.trim() ?? '';
    if (owner.isEmpty) return false;
    final me = SessionService.currentUserNotifier.value;
    if (me == null || me.id.trim().isEmpty) return false;
    return owner == me.id.trim();
  }

  Future<void> _toggleLike(OfferCommentNorm comment) async {
    if (comment.isLegacyAnswer) return;
    final previousLiked = comment.viewerLiked ?? false;
    final previousCount = comment.likeCount ?? 0;
    final optimistic = comment.copyWith(
      viewerLiked: !previousLiked,
      likeCount: previousLiked
          ? (previousCount - 1).clamp(0, 1 << 30)
          : previousCount + 1,
    );
    setState(() {
      _comments = _comments
          .map((c) => c.id == comment.id ? optimistic : c)
          .toList(growable: false);
    });

    try {
      final r = await OfferCommentsService.toggleOfferQaCommentLike(
        widget.offerId,
        comment.id,
      );
      if (!mounted) return;
      setState(() {
        _comments = _comments
            .map((c) => c.id == comment.id
                ? c.copyWith(
                    viewerLiked: r.liked,
                    likeCount: r.likeCount,
                  )
                : c)
            .toList(growable: false);
      });
    } on UnauthorizedException {
      _restoreCommentLike(comment.id, previousLiked, previousCount);
      _toast('Inicia sesión para dar me gusta.');
    } catch (e) {
      _restoreCommentLike(comment.id, previousLiked, previousCount);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _restoreCommentLike(String commentId, bool liked, int count) {
    if (!mounted) return;
    setState(() {
      _comments = _comments
          .map((c) => c.id == commentId
              ? c.copyWith(viewerLiked: liked, likeCount: count)
              : c)
          .toList(growable: false);
    });
  }

  Future<void> _submit() async {
    final me = SessionService.currentUserNotifier.value;
    final text = _draftCtrl.text.trim();
    if (text.isEmpty) return;
    if (me == null || me.id.trim().isEmpty) {
      _toast('Inicia sesión para comentar.');
      return;
    }
    if (_isOwnOffer && _replyingTo == null) return;

    setState(() => _sending = true);
    try {
      await OfferCommentsService.submitOfferQuestion(
        widget.offerId,
        text,
        OfferCommentAuthor(
          id: me.id,
          name: me.name.trim().isNotEmpty ? me.name.trim() : 'Anónimo',
          trustScore: me.trustScore ?? 0,
        ),
        parentId: _replyingTo?.id,
      );
      if (!mounted) return;
      _draftCtrl.clear();
      final wasReplying = _replyingTo != null;
      setState(() => _replyingTo = null);
      _toast(wasReplying ? 'Respuesta enviada' : 'Comentario enviado');
      await _loadComments();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_listCtrl.hasClients) {
          _listCtrl.animateTo(
            _listCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    } on UnauthorizedException {
      _toast('Tu sesión expiró. Inicia sesión de nuevo.');
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

  Map<String?, List<OfferCommentNorm>> _buildTree() {
    final byParent = <String?, List<OfferCommentNorm>>{};
    for (final c in _comments) {
      byParent.putIfAbsent(c.parentId, () => <OfferCommentNorm>[]).add(c);
    }
    for (final list in byParent.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return byParent;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfileModel?>(
      valueListenable: SessionService.currentUserNotifier,
      builder: (context, me, _) {
        final sessionReady = me != null && me.id.trim().isNotEmpty;
        final canEngageLikes = sessionReady;
        final isOwn = _isOwnOffer;
        final composerLocked =
            !sessionReady || (isOwn && _replyingTo == null);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.foregroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comentarios públicos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mismo hilo que en el chat al abrir la compra: identidad y '
                'confianza visibles. El vendedor responde con «Responder» '
                '(no puede iniciar un hilo nuevo en su propia ficha).',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: AppTheme.dividerColor, height: 1),
              const SizedBox(height: 12),
              _buildList(canEngageLikes, sessionReady),
              const SizedBox(height: 12),
              _buildComposer(
                me: me,
                sessionReady: sessionReady,
                composerLocked: composerLocked,
                isOwn: isOwn,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(bool canEngageLikes, bool sessionReady) {
    if (_loading) {
      return Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 24),
            const SizedBox(height: 6),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadComments,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_comments.isEmpty) {
      return Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 28,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'Aún no hay comentarios.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sessionReady
                  ? '¡Sé el primero en comentar!'
                  : 'Inicia sesión para ser el primero en comentar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final tree = _buildTree();
    return Container(
      constraints: const BoxConstraints(maxHeight: 420, minHeight: 120),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        controller: _listCtrl,
        primary: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _renderThread(
            tree,
            parentId: null,
            depth: 0,
            canEngageLikes: canEngageLikes,
            sessionReady: sessionReady,
          ),
        ),
      ),
    );
  }

  List<Widget> _renderThread(
    Map<String?, List<OfferCommentNorm>> tree, {
    required String? parentId,
    required int depth,
    required bool canEngageLikes,
    required bool sessionReady,
  }) {
    final rows = tree[parentId] ?? const <OfferCommentNorm>[];
    final out = <Widget>[];
    for (final c in rows) {
      out.add(_buildCommentTile(
        c,
        depth: depth,
        canEngageLikes: canEngageLikes,
        sessionReady: sessionReady,
      ));
      final replies = tree[c.id];
      if (replies != null && replies.isNotEmpty) {
        out.add(Padding(
          padding: const EdgeInsets.only(left: 12, top: 2, bottom: 4),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppTheme.dividerColor,
                  width: 2,
                ),
              ),
            ),
            padding: const EdgeInsets.only(left: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _renderThread(
                tree,
                parentId: c.id,
                depth: depth + 1,
                canEngageLikes: canEngageLikes,
                sessionReady: sessionReady,
              ),
            ),
          ),
        ));
      }
    }
    return out;
  }

  Widget _buildCommentTile(
    OfferCommentNorm c, {
    required int depth,
    required bool canEngageLikes,
    required bool sessionReady,
  }) {
    final me = SessionService.currentUserNotifier.value;
    final ownerId = widget.storeOwnerUserId?.trim() ?? '';
    final isSellerComment = ownerId.isNotEmpty && c.author.id == ownerId;
    final ctx = OfferCommentAuthorContext(
      viewerId: me?.id ?? '',
      viewerName: me?.name ?? '',
    );
    final authorLabel = resolveOfferCommentAuthorLabel(c.author, ctx);
    final trustScore = (me != null && c.author.id == me.id)
        ? (me.trustScore ?? c.author.trustScore)
        : c.author.trustScore;

    return Padding(
      padding: EdgeInsets.only(top: depth > 0 ? 6 : 10, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                authorLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (isSellerComment) const SellerBadge(),
              TrustChip(score: trustScore),
              Text(
                timeAgo(c.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!c.isLegacyAnswer)
                Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: CommentLikeButton(
                    likeCount: c.likeCount ?? 0,
                    liked: c.viewerLiked ?? false,
                    onPressed: () => _toggleLike(c),
                    enabled: canEngageLikes,
                  ),
                ),
              Expanded(
                child: Text(
                  c.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (sessionReady)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CommentReplyButton(
                onPressed: () {
                  setState(() => _replyingTo = c);
                  _inputFocus.requestFocus();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComposer({
    required UserProfileModel? me,
    required bool sessionReady,
    required bool composerLocked,
    required bool isOwn,
  }) {
    final placeholder = !sessionReady
        ? 'Inicia sesión para comentar…'
        : (composerLocked
            ? 'Elige «Responder» en un comentario…'
            : (_replyingTo != null
                ? 'Escribe una respuesta…'
                : 'Escribe un comentario…'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_replyingTo != null)
            ReplyingToIndicator(
              comment: _replyingTo!,
              authorLabel: resolveOfferCommentAuthorLabel(
                _replyingTo!.author,
                OfferCommentAuthorContext(
                  viewerId: me?.id ?? '',
                  viewerName: me?.name ?? '',
                ),
              ),
              onCancel: () => setState(() => _replyingTo = null),
            ),
          if (!sessionReady) const SessionRequiredMessage(),
          if (sessionReady && composerLocked) const SellerOnlyReplyMessage(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _draftCtrl,
                  focusNode: _inputFocus,
                  enabled: !_sending && !composerLocked,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.foregroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
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
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: AppTheme.primaryColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending || composerLocked ? null : _submit,
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
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
        ],
      ),
    );
  }
}
