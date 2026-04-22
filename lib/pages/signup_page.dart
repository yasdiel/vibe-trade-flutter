import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/country_services.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/phone_input.dart';
import '../models/country_model.dart';
import '../widgets/intro_btn.dart';
import '../widgets/OtpSheet.dart';

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

  /*@override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    setState(() {
      _loadingCountrys = true;
    });
    _countries = await CountryServices.getCountries();
    setState(() {
      _loadingCountrys = false;
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png'),
            _loadingCountrys
                ? CircularProgressIndicator()
                : PhoneInput(
                    countries: _countries,
                    onChanged: (code, number) {
                      setState(() {
                        _phoneCode = code;
                        _phoneNumber = number;
                      });
                    },
                  ),
            SizedBox(height: 20),
            if (_showError)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Por favor ingresa un número de teléfono válido',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            SizedBox(height: 10),
            IntroBtn(
              text: 'Registrarme',
              onTap: () {
                if (_phoneNumber.length < 7) {
                  setState(() => _showError = true);
                  Future.delayed(const Duration(seconds: 3), () {
                    setState(() => _showError = false);
                  });
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  builder: (context) =>
                      OtpSheet(phoneNumber: _phoneNumber, code: _phoneCode),
                  isScrollControlled: true,
                );
              },
            ),
            SizedBox(height: 10),
            Text(
              'Ya tienes una cuenta?',
              style: TextStyle(
                color: const Color.fromARGB(255, 134, 125, 125),
                fontSize: 16,
                fontWeight: FontWeight(600),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: Text(
                'Inicia Sesión',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight(700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
