import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/offer_comment_model.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Formatea timestamp a formato relativo (ej: "hace 5 min")
String timeAgo(int timestampMs) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final seconds = ((now - timestampMs) / 1000).floor();

  if (seconds < 60) return 'ahora';
  if (seconds < 3600) return 'hace ${(seconds / 60).floor()} min';
  if (seconds < 86400) return 'hace ${(seconds / 3600).floor()} h';
  return 'hace ${(seconds / 86400).floor()} d';
}

/// Chip que muestra la puntuación de confianza
class TrustChip extends StatelessWidget {
  final int score;
  final String title;

  const TrustChip({
    required this.score,
    this.title = 'Indicador de confianza del autor.',
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.inputFillColor,
        ),
        child: Text(
          'Confianza: $score',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Botón de respuesta para comentarios
class CommentReplyButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CommentReplyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Text(
            'Responder',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de like para comentarios
class CommentLikeButton extends StatelessWidget {
  final int likeCount;
  final bool liked;
  final VoidCallback onPressed;
  final bool enabled;

  const CommentLikeButton({
    required this.likeCount,
    required this.liked,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              likeCount.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppTheme.inputFillColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: liked ? AppTheme.errorColor : AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                likeCount.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: liked ? AppTheme.errorColor : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge que indica que el comentario es del vendedor
class SellerBadge extends StatelessWidget {
  const SellerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.successColor.withValues(alpha: 0.1),
      ),
      child: Text(
        'Vendedor',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

/// Indicador de respuesta activa
class ReplyingToIndicator extends StatelessWidget {
  final OfferCommentNorm comment;
  final String authorLabel;
  final VoidCallback onCancel;

  const ReplyingToIndicator({
    required this.comment,
    required this.authorLabel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: AppTheme.successColor, width: 4),
        ),
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respondiendo a $authorLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Cancelar respuesta',
          ),
        ],
      ),
    );
  }
}

/// Mensaje de estado vacío de comentarios
class EmptyCommentsPlaceholder extends StatelessWidget {
  const EmptyCommentsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Aún no hay comentarios.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Mensaje de sesión requerida
class SessionRequiredMessage extends StatelessWidget {
  const SessionRequiredMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Inicia sesión para comentar y dar me gusta en esta ficha.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}

/// Mensaje para vendedores
class SellerOnlyReplyMessage extends StatelessWidget {
  const SellerOnlyReplyMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Como vendedor, usa Responder en un comentario para publicar aquí.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}
