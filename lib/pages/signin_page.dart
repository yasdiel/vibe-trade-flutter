import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/desktop_auth_layout.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';
import '../models/country_model.dart';
import '../widgets/intro_btn.dart';
import '../widgets/phone_input.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  String _phoneCode = '';
  String _phoneNumber = '';
  final List<CountryModel> _countries = [
    CountryModel(name: 'Cuba', code: '+53', flag: 'Cu'),
  ];

  bool _loadingCountrys = false;
  bool _showError = false;

  void _handleLogin() {
    if (_phoneNumber.length < 7) {
      setState(() => _showError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showError = false);
        }
      });
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  Widget _buildForm({required bool isDesktop, required double width}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDesktop) ...[
          Center(child: Image.asset('assets/images/logo.png')),
          const SizedBox(height: 24),
        ],
        _loadingCountrys
            ? const CircularProgressIndicator()
            : PhoneInput(
                countries: _countries,
                onChanged: (code, number) {
                  setState(() {
                    _phoneCode = code;
                    _phoneNumber = number;
                  });
                },
              ),
        const SizedBox(height: 20),
        if (_showError)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Por favor ingresa un numero de telefono valido',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Center(
          child: IntroBtn(
            text: 'Iniciar Sesion',
            width: isDesktop ? width : 250,
            height: isDesktop ? 46 : 40,
            onTap: _handleLogin,
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Aun no tienes una cuenta?',
            style: TextStyle(
              color: Color.fromARGB(255, 134, 125, 125),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: InkWell(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/signup');
            },
            child: Text(
              'Registrate',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBody() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: _buildForm(isDesktop: false, width: 250),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopBody() {
    return DesktopAuthLayout(
      title: 'Inicia sesion en VibeTrade',
      subtitle: '',
      form: _buildForm(isDesktop: true, width: 356),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(body: isDesktop ? _buildDesktopBody() : _buildMobileBody());
  }
}
