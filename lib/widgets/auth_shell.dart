import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.selectedColor,
            AppTheme.appBgColor,
            AppTheme.accentGreenSurfaceColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.desktopContentMaxWidth,
                    minHeight: constraints.maxHeight > 0
                        ? constraints.maxHeight
                        : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: AppTheme.primaryColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: AppTheme.foregroundColor
                                          .withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: const Icon(
                                      Icons.storefront_outlined,
                                      size: 34,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 34,
                                      height: 1.1,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.foregroundColor,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: AppTheme.foregroundColor
                                          .withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.foregroundColor,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 26,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: _ScrollableAuthContent(child: child),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScrollableAuthContent extends StatelessWidget {
  final Widget child;

  const _ScrollableAuthContent({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0.0;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
