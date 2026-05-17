import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// SnackBar dentro de un [Dialog] con [Scaffold] (ver [showModalFormDialog]).
void showModalSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
}

void showModalError(BuildContext context, String message) {
  showModalSnackBar(context, message, backgroundColor: AppTheme.errorColor);
}
