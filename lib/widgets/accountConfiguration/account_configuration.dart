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
  void _showPaymentGatewaysDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.foregroundColor,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentGreenSurfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppTheme.accentGreenColor,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pasarelas de pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Aqui podras conectar y administrar tus metodos de cobro cuando esta configuracion este disponible.',
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentGreenColor,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color borderColor,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            _buildActionButton(
              label: 'Configurar pasarelas de pago',
              icon: Icons.account_balance_wallet_outlined,
              onTap: _showPaymentGatewaysDialog,
              borderColor: AppTheme.accentGreenColor,
              backgroundColor: AppTheme.accentGreenSurfaceColor,
              foregroundColor: AppTheme.accentGreenColor,
            ),
            const SizedBox(height: 14),

            //Cerrar Sesion
            _buildActionButton(
              label: 'Cerrar Sesion',
              icon: Icons.logout,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/signin');
              },
              borderColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.foregroundColor,
              foregroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
