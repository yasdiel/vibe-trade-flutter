import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/contacts_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/email_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/image_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/phone_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/social_media_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/username_configuration.dart';

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
            const SizedBox(height: 20),

            // Agenda
            ContactsConfiguration(),
            SizedBox(height: 20),

            // Social Media
            SocialMediaConfiguration(),
            SizedBox(height: 20),

            // Pasarelas de pago

            //Cerrar Sesion
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(5),

                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/signin');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.foregroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          size: 17,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Cerrar Sesion',
                          style: TextStyle(
                            fontSize: 17,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight(600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
