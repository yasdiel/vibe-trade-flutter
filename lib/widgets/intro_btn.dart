import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IntroBtn extends StatelessWidget {
  final String text;
  final GestureTapCallback? onTap;
  final double width;
  final double height;
  final bool enabled;

  const IntroBtn({
    super.key,
    required this.text,
    required this.onTap,
    this.width = 250,
    this.height = 40,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = enabled
        ? AppTheme.primaryColor
        : AppTheme.primaryColor.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundColor.withValues(
                alpha: enabled ? 1 : 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
