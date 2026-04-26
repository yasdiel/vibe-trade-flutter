import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/account_configuration.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AuthService.currentUserNotifier,
      builder: (context, user, _) {
        return ConfiguracionUsuario(user: user);
      },
    );
  }
}
