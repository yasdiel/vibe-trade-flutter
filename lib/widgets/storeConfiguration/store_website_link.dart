import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/utils/website_url.dart';

/// Enlace al sitio web de una tienda (abre en el navegador del sistema).
class StoreWebsiteLink extends StatelessWidget {
  final String url;
  final TextAlign textAlign;
  final int? maxLines;
  final double fontSize;
  final bool showIcon;

  const StoreWebsiteLink({
    super.key,
    required this.url,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.fontSize = 13,
    this.showIcon = false,
  });

  Future<void> _open(BuildContext context) async {
    final ok = await launchWebsiteUrl(url);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el sitio web')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeOwnerWebsiteUrl(url);
    if (normalized == null) return const SizedBox.shrink();

    final label = websiteUrlDisplayLabel(normalized);
    final link = Text(
      label,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppTheme.primaryColor,
        decoration: TextDecoration.underline,
        decorationColor: AppTheme.primaryColor,
      ),
    );

    final tappable = InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: link,
      ),
    );

    if (!showIcon) {
      return Align(
        alignment: textAlign == TextAlign.end
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: tappable,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.public, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(child: tappable),
      ],
    );
  }
}
