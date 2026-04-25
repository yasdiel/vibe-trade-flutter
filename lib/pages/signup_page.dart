import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/desktop_auth_layout.dart';
import 'package:vibe_trade_v1/widgets/phone_input.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';
import '../models/country_model.dart';
import '../widgets/intro_btn.dart';
import '../widgets/otp_sheet.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String _phoneCode = '';
  String _phoneNumber = '';
  final List<CountryModel> _countries = [
    CountryModel(name: 'Cuba', code: '+53', flag: 'Cu'),
  ];

  bool _loadingCountrys = false;
  bool _showError = false;

  void _handleRegister() {
    if (_phoneNumber.length < 7) {
      setState(() => _showError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showError = false);
        }
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) =>
          OtpSheet(phoneNumber: _phoneNumber, code: _phoneCode),
      isScrollControlled: true,
    );
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
            text: 'Registrarme',
            width: isDesktop ? width : 250,
            height: isDesktop ? 46 : 40,
            onTap: _handleRegister,
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Ya tienes una cuenta?',
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
              Navigator.pushReplacementNamed(context, '/signin');
            },
            child: Text(
              'Inicia Sesion',
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
      title: 'Crea tu cuenta en VibeTrade',
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
