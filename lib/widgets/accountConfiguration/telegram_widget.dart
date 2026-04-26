import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import '../../theme/app_theme.dart';

class TelegramWidget extends StatefulWidget {
  final String initialValue;

  const TelegramWidget({super.key, this.initialValue = ''});

  @override
  State<TelegramWidget> createState() => _TelegramWidgetState();
}

class _TelegramWidgetState extends State<TelegramWidget> {
  late final TextEditingController _telegramController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _telegramController = TextEditingController(text: widget.initialValue);
  }

  Future<void> _guardarTelegram() async {
    final telegram = _telegramController.text.trim();

    if (telegram.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El usuario o enlace no puede estar vacio'),
        ),
      );
      return;
    }

    final esUsuario = RegExp(
      r'^[a-zA-Z][a-zA-Z0-9_]{4,31}$',
    ).hasMatch(telegram);
    final esUrl =
        telegram.startsWith('https://t.me/') ||
        telegram.startsWith('http://t.me/');

    if (!esUsuario && !esUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Introduce un usuario de Telegram valido o un enlace t.me',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AuthService.updateUserProfile(telegram: telegram);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Telegram guardado: $telegram')));
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  void dispose() {
    _telegramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Usuario o enlace',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Campo Email + Boton Guardar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _telegramController,
                decoration: InputDecoration(
                  hintText: 'username o https://...',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.foregroundColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: _saving
                  ? null
                  : () {
                Navigator.pop(context);
              },

              child: Center(
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight(700),
                  ),
                ),
              ),
            ),
            SizedBox(width: 5),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: _saving ? null : _guardarTelegram,

              child: Center(
                child: Text(
                  _saving ? 'Guardando...' : 'Guardar',
                  style: TextStyle(
                    color: AppTheme.foregroundColor,
                    fontSize: 13,
                    fontWeight: FontWeight(700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
