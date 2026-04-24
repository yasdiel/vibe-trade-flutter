import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/widgets/account_configuration.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return ConfiguracionUsuario();
  }
}
