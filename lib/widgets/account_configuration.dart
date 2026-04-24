import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/email_configuration.dart';
import 'package:vibe_trade_v1/widgets/image_account.dart';
import 'package:vibe_trade_v1/widgets/phone_configuration.dart';
import 'package:vibe_trade_v1/widgets/username_account.dart';

class ConfiguracionUsuario extends StatefulWidget {
  const ConfiguracionUsuario({super.key});

  @override
  State<ConfiguracionUsuario> createState() => _ConfiguracionUsuarioState();
}

class _ConfiguracionUsuarioState extends State<ConfiguracionUsuario> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Container(
              padding: EdgeInsets.only(bottom: 5),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 1.0),
                ),
              ),
              child: const Text(
                'Configuración del usuario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Foto de perfil
            ImageAccount(),
            const SizedBox(height: 20),

            // Nombre de usuario
            UsernameAccount(),
            const SizedBox(height: 20),

            // Email
            EmailConfiguration(),
            const SizedBox(height: 20),

            //Phone Number
            PhoneConfiguration(),
          ],
        ),
      ),
    );
  }
}
