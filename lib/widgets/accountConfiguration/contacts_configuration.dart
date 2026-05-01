import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/agend_phone_configuration.dart';

class ContactsConfiguration extends StatefulWidget {
  const ContactsConfiguration({super.key});

  @override
  State<ContactsConfiguration> createState() => _ContactsConfigurationState();
}

class _ContactsConfigurationState extends State<ContactsConfiguration> {
  void _showContactsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        shadowColor: AppTheme.primaryColor,
        content: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contactos',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              Text(
                'Solo puedes guardar numeros que esten registrados en VibeTrade',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              SizedBox(height: 15),
              AgendPhoneConfiguration(),
            ],
          ),
        ),
        backgroundColor: AppTheme.foregroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.contacts, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Agenda en la plataforma',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Guarda el numero de otros usuarios registrados para verlos con nombre y telefono del perfil',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _showContactsDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Contactos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
