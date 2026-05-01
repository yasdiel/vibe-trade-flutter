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
              Expanded(child: _UserGreeting(user: user))
            else
              const Expanded(child: _GuestBadge()),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Notificaciones',
              onPressed: onNotificationsTap,
              icon: Icon(
                Icons.notifications_none_outlined,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserGreeting extends StatelessWidget {
  final UserProfileModel? user;

  const _UserGreeting({this.user});

  @override
  Widget build(BuildContext context) {
    final name = (user?.name ?? '').trim();
    final firstName = name.isEmpty ? 'Usuario' : name.split(' ').first;
    final initial = firstName[0].toUpperCase();
    final imageUrl = user?.imageUrl ?? '';

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _AvatarFallback(initial: initial),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _AvatarFallback(initial: initial);
                  },
                )
              : _AvatarFallback(initial: initial),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hola,',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initial;

  const _AvatarFallback({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GuestBadge extends StatelessWidget {
  const _GuestBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.warningSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 16, color: AppTheme.warningColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Modo visitante',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
