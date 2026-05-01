import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class ModalTitle extends StatelessWidget {
  final String text;
  const ModalTitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    );
  }
}
