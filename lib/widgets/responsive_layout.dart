import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1100;
  static const double desktopContentMaxWidth = 1280;
  static const double desktopBodyMaxWidth = 1080;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;
}

class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveLayout.desktopBodyMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
