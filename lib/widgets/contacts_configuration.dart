import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class ContactsConfiguration extends StatefulWidget {
  const ContactsConfiguration({super.key});

  @override
  State<ContactsConfiguration> createState() => _ContactsConfigurationState();
}

class _ContactsConfigurationState extends State<ContactsConfiguration> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.contacts, size: 16, color: Colors.black54),
            SizedBox(width: 6),
            Text(
              'Agenda en la plataforma',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        Text(
          'Guarda el numero de otros usuarios registrados para verlos con nombre y telefono del perfil',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight(500),
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10),
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
                    color: AppTheme.foregroundColor,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Contactos',
                    style: TextStyle(
                      color: AppTheme.foregroundColor,
                      fontWeight: FontWeight(700),
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
