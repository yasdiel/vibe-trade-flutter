import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import '../../theme/app_theme.dart';

class EmailConfiguration extends StatefulWidget {
  final String initialValue;

  const EmailConfiguration({super.key, this.initialValue = ''});

  @override
  State<EmailConfiguration> createState() => _EmailConfigurationState();
}

class _EmailConfigurationState extends State<EmailConfiguration> {
  late final TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialValue);
  }

  Future<void> _guardarEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El email no puede estar vacio')),
      );
      return;
    }

    if (email.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El email no puede contener espacios')),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un email valido con @ y un .'),
        ),
      );
      return;
    }

    final partes = email.split('@');
    if (partes.length != 2 || partes.first.isEmpty || partes.last.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un email valido')),
      );
      return;
    }

    if (!partes.last.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El dominio del email no es valido')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AuthService.updateUserProfile(email: email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Email guardado: $email')));
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
  void didUpdateWidget(covariant EmailConfiguration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _emailController.text != widget.initialValue) {
      _emailController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Icon(Icons.email, size: 16, color: Colors.black54),
            SizedBox(width: 6),
            Text(
              'Email (requerido)',
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
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'user@exmple.com',
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
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _saving ? null : _guardarEmail,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_saving ? 'Guardando...' : 'Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.foregroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
