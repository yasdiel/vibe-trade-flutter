import 'package:flutter/material.dart';

/// Placeholder por defecto cuando un servicio no tiene foto en la ficha.
class ServiceImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double iconSize;
  final BorderRadius? borderRadius;

  const ServiceImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.iconSize = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.handyman_outlined,
        size: iconSize,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }
}
