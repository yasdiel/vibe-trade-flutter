import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Estado de búsqueda
enum SearchStatus { idle, loading, ready, error }

/// Texto informativo con icono para diferentes estados
class HelperText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const HelperText({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: c,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de paginación con botones anterior/siguiente
class PaginationRow extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const PaginationRow({
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: hasPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left, size: 16),
          label: const Text('Anterior'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: hasNext ? onNext : null,
          icon: const Icon(Icons.chevron_right, size: 16),
          label: const Text('Siguiente'),
        ),
      ],
    );
  }
}
