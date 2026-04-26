import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class TrustAppBarActions extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback? onNotificationsTap;

  const TrustAppBarActions({
    super.key,
    required this.isLoggedIn,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfileModel?>(
      valueListenable: AuthService.currentUserNotifier,
      builder: (context, user, _) {
        return Row(
          children: [
            if (isLoggedIn)
              Expanded(child: TrustBar(score: user?.trustScore))
            else
              const Expanded(child: _GuestBadge()),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_none_outlined),
            ),
          ],
        );
      },
    );
  }
}

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
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Confianza',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor(int? value) {
    if (value == null) return Colors.black38;
    if (value < 30) return Colors.redAccent;
    if (value <= 60) return Colors.amber.shade700;
    return Colors.green;
  }
}

class _GuestBadge extends StatelessWidget {
  const _GuestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Modo visitante',
        style: TextStyle(
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
