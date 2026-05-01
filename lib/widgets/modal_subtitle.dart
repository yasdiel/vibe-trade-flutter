import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class ModalSubtitle extends StatelessWidget {
  final String text;
  const ModalSubtitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
    );
  }
}
