import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Muestra un formulario en [Dialog] con [Scaffold] propio para que los
/// SnackBar de validacion queden por encima del contenido del modal.
Future<T?> showModalFormDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) {
      final size = MediaQuery.sizeOf(dialogContext);
      final isWide = size.width >= 720;
      return Dialog(
        backgroundColor: AppTheme.foregroundColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: isWide
            ? const EdgeInsets.symmetric(horizontal: 40, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 540 : double.infinity,
              maxHeight: size.height * 0.92,
            ),
            child: Padding(
              padding: EdgeInsets.all(isWide ? 22 : 18),
              child: SingleChildScrollView(child: child),
            ),
          ),
        ),
      );
    },
  );
}
