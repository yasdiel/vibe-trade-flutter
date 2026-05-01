import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class TrustBar extends StatelessWidget {
  final int? score;

  const TrustBar({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final safeScore = score?.clamp(0, 100);
    final progressColor = _progressColor(safeScore);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confianza',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                safeScore == null ? 'Sin dato' : '$safeScore%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: safeScore == null ? 0 : safeScore / 100,
              backgroundColor: AppTheme.surfaceMutedColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(int? value) {
    if (value == null) return AppTheme.textMuted;
    if (value < 30) return AppTheme.errorColor;
    if (value <= 60) return AppTheme.warningColor;
    return AppTheme.successColor;
  }
}
