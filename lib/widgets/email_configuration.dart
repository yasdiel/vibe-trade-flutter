import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmailConfiguration extends StatefulWidget {
  const EmailConfiguration({super.key});

  @override
  State<EmailConfiguration> createState() => _EmailConfigurationState();
}

class _EmailConfigurationState extends State<EmailConfiguration> {
  final TextEditingController _emailController = TextEditingController(
    text: '',
  );

  void _guardarEmail() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Email guardado: ${_emailController.text}')),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
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
              onPressed: _guardarEmail,
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
