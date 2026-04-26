import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class PhoneConfiguration extends StatefulWidget {
  final String initialValue;

  const PhoneConfiguration({super.key, this.initialValue = ''});

  @override
  State<PhoneConfiguration> createState() => _PhoneConfigurationState();
}

class _PhoneConfigurationState extends State<PhoneConfiguration> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PhoneConfiguration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _phoneController.text != widget.initialValue) {
      _phoneController.text = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Icon(Icons.phone, size: 16, color: Colors.black54),
            SizedBox(width: 6),
            Text(
              'Phone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: Tooltip(
              message: 'Este campo no es editable',
              child: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}
