import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class OtpSheet extends StatefulWidget {
  final String phoneNumber;
  final String code;
  final String? mode;

  const OtpSheet({
    super.key,
    required this.phoneNumber,
    required this.code,
    this.mode,
  });

  @override
  State<OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<OtpSheet> {
  static const int _otpLength = 7;
  static const int _resendDelaySeconds = 30;

  bool _showError = false;
  bool _showVerifyError = false;
  bool _showResendError = false;
  bool _verifyingCode = false;
  bool _resendingCode = false;
  int _resendSecondsRemaining = _resendDelaySeconds;
  Timer? _resendTimer;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length < _otpLength) {
      setState(() => _showError = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showError = false);
        }
      });
      return;
    }

    setState(() {
      _verifyingCode = true;
      _showVerifyError = false;
    });

    try {
      await AuthService.verifyCode(
        phone: widget.phoneNumber,
        code: code,
        mode: widget.mode,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _verifyingCode = false;
        _showVerifyError = true;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _verifyingCode = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = _resendDelaySeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
        return;
      }

      setState(() => _resendSecondsRemaining--);
    });
  }

  Future<void> _handleResendCode() async {
    if (_resendSecondsRemaining > 0 || _resendingCode) {
      return;
    }

    setState(() {
      _resendingCode = true;
      _showResendError = false;
    });

    try {
      await AuthService.requestCode(phone: widget.phoneNumber, mode: widget.mode);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _showResendError = true);
    } finally {
      if (!mounted) {
        return;
      }
      setState(() => _resendingCode = false);
    }

    if (_showResendError) {
      return;
    }

    _startResendCountdown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa el codigo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Te enviamos un codigo de $_otpLength digitos por SMS al numero ${widget.code} ${widget.phoneNumber}',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                _otpLength,
                (i) => SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    key: ValueKey('otp-field-$i'),
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => _onChanged(value, i),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade300,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_showError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'El codigo debe tener $_otpLength digitos.',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (_showVerifyError)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No se pudo verificar el codigo. Intenta nuevamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                  ),
                ),
            if (_showResendError)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No se pudo reenviar el codigo. Intenta nuevamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _resendSecondsRemaining > 0
                  ? Text(
                      'Puedes solicitar un nuevo codigo en $_resendSecondsRemaining s',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : TextButton(
                      onPressed: _resendingCode ? null : _handleResendCode,
                      child: Text(
                        _resendingCode
                            ? 'Reenviando codigo...'
                            : 'Solicitar codigo nuevamente',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    AppTheme.primaryColor,
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                onPressed: _verifyingCode ? null : _handleVerify,
                child: Text(
                  _verifyingCode ? 'Verificando...' : 'Verificar',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.foregroundColor,
                    fontWeight: FontWeight.w600,
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
