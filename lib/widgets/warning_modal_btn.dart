import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class WarningModalBtn extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Icon icon;
  const WarningModalBtn({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      label: Text(text, style: TextStyle(color: AppTheme.primaryColor)),
      icon: icon,
      style: TextButton.styleFrom(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        minimumSize: Size(double.infinity, 40),
      ),
    );
  }
}
