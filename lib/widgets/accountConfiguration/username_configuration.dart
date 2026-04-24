import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class UsernameAccount extends StatefulWidget {
  const UsernameAccount({super.key});

  @override
  State<UsernameAccount> createState() => _UsernameAccountState();
}

class _UsernameAccountState extends State<UsernameAccount> {
  final TextEditingController _nombreController = TextEditingController(
    text: '',
  );

  void _guardarNombre() {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nombre guardado: $nombre')),
    );
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
              onPressed: _guardarNombre,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Guardar'),
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
