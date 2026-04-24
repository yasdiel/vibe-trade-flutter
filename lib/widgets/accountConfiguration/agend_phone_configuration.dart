import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AgendPhoneConfiguration extends StatefulWidget {
  const AgendPhoneConfiguration({super.key});

  @override
  State<AgendPhoneConfiguration> createState() =>
      _AgendPhoneConfigurationState();
}

class _AgendPhoneConfigurationState extends State<AgendPhoneConfiguration> {
  final TextEditingController _phoneController = TextEditingController();
  void _guardarNumero() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Numero guardado: ${_phoneController.text}')),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
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
              'Numero de telefono',
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
                style: TextStyle(fontSize: 14),
                controller: _phoneController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Ej. +53 34567434',
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
            ElevatedButton.icon(
              onPressed: _guardarNumero,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.foregroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        Divider(height: 1, color: Colors.grey),
        SizedBox(
          height: 200,
          child: Center(child: Text('No tienes contactos registrados')),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.foregroundColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: () {
                Navigator.pop(context);
              },

              child: Center(
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 15,
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
