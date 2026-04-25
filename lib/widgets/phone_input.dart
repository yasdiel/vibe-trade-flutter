import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import '../models/country_model.dart';

class PhoneInput extends StatefulWidget {
  final List<CountryModel> countries;
  final Function(String code, String number) onChanged;

  const PhoneInput({
    super.key,
    required this.countries,
    required this.onChanged,
  });

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  CountryModel? _selectedCountry;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    // Select the first one for default
    if (widget.countries.isNotEmpty) {
      _selectedCountry = widget.countries.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country Select
              Text('País', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CountryModel>(
                    isExpanded: true,
                    value: _selectedCountry,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: widget.countries.map((country) {
                      return DropdownMenuItem(
                        value: country,
                        child: Row(
                          children: [
                            Text(
                              country.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              country.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(country.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCountry = value);
                      widget.onChanged(
                        _selectedCountry!.code,
                        _phoneController.text,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Input of the number
              Text('Número', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 18),
                        SizedBox(width: 6),
                        Text(
                          _selectedCountry?.code ?? '',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '11 5555 5555',
                      ),
                      onChanged: (value) {
                        widget.onChanged(_selectedCountry?.code ?? '', value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
