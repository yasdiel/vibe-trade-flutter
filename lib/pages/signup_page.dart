import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/desktop_auth_layout.dart';
import 'package:vibe_trade_v1/widgets/phone_input.dart';
import 'package:vibe_trade_v1/widgets/responsive_layout.dart';
import '../models/country_model.dart';
import '../services/auth_service.dart';
import '../services/country_services.dart';
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
  List<CountryModel> _countries = [];

  bool _loadingCountrys = false;
  bool _loadingCountrysError = false;
  bool _requestingCode = false;
  bool _showError = false;
  bool _showRequestError = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _loadingCountrys = true;
      _loadingCountrysError = false;
    });

    try {
      final countries = await CountryServices.getCountries();
      if (!mounted) {
        return;
      }

      setState(() {
        _countries = countries;
        _loadingCountrys = false;
        _loadingCountrysError = false;
        if (countries.isNotEmpty) {
          _phoneCode = countries.first.dial;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingCountrys = false;
        _loadingCountrysError = true;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (_phoneNumber.length < 7) {
      setState(() => _showError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showError = false);
        }
      });
      return;
    }

    setState(() {
      _requestingCode = true;
      _showRequestError = false;
    });

    try {
      await AuthService.requestRegisterCode(phone: _phoneNumber);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _requestingCode = false;
        _showRequestError = true;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _requestingCode = false);
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          OtpSheet(
            phoneNumber: _phoneNumber,
            code: _phoneCode,
            mode: 'register',
          ),
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
        _buildCountrySection(isDesktop: isDesktop, width: width),
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
        if (_showRequestError)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'No se pudo solicitar el codigo. Intenta nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 10),
        Center(
          child: IntroBtn(
            text: _requestingCode ? 'Solicitando codigo...' : 'Registrarme',
            width: isDesktop ? width : 250,
            height: isDesktop ? 46 : 40,
            enabled:
                !_loadingCountrys && !_loadingCountrysError && !_requestingCode,
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
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: Text(
              'Continuar sin cuenta',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountrySection({required bool isDesktop, required double width}) {
    if (_loadingCountrys) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Cargando paises...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromARGB(255, 134, 125, 125),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingCountrysError) {
      return Center(
        child: Column(
          children: [
            const Text(
              'Hubo un error al cargar los paises.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: isDesktop ? width : 250,
              child: OutlinedButton.icon(
                onPressed: _loadCountries,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(isDesktop ? width : 250, isDesktop ? 46 : 40),
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  backgroundColor: AppTheme.selectedColor,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PhoneInput(
      countries: _countries,
      onChanged: (code, number) {
        setState(() {
          _phoneCode = code;
          _phoneNumber = number;
        });
      },
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
