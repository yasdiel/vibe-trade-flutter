import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import '../../theme/app_theme.dart';

class UsernameAccount extends StatefulWidget {
  final String initialValue;

  const UsernameAccount({super.key, this.initialValue = ''});

  @override
  State<UsernameAccount> createState() => _UsernameAccountState();
}

class _UsernameAccountState extends State<UsernameAccount> {
  late final TextEditingController _nombreController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.initialValue);
  }

  Future<void> _guardarNombre() async {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacio')),
      );
      return;
    }

    if (nombre.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre debe tener al menos 3 caracteres'),
        ),
      );
      return;
    }

    if (RegExp(r'^\d+$').hasMatch(nombre)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar formado solo por numeros'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await AuthService.updateUserProfile(name: nombre);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nombre guardado: $nombre')));
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
  void didUpdateWidget(covariant UsernameAccount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _nombreController.text != widget.initialValue) {
      _nombreController.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Icon(Icons.person_outline, size: 16, color: Colors.black54),
            SizedBox(width: 6),
            Text(
              'Nombre',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Campo nombre + botón Guardar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Jhon Doe',
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
              onPressed: _saving ? null : _guardarNombre,
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
