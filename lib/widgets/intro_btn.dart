import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IntroBtn extends StatelessWidget {
  final String text;
  final GestureTapCallback onTap;
  final double width;
  final double height;

  const IntroBtn({
    super.key,
    required this.text,
    required this.onTap,
    this.width = 250,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}
