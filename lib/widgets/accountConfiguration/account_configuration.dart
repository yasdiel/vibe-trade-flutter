import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/user_profile_model.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/contacts_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/email_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/image_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/phone_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/social_media_configuration.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/theme_switcher.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/username_configuration.dart';
import 'package:vibe_trade_v1/widgets/trust_bar.dart';

class ConfiguracionUsuario extends StatefulWidget {
  final UserProfileModel? user;

  const ConfiguracionUsuario({super.key, this.user});

  @override
  State<ConfiguracionUsuario> createState() => _ConfiguracionUsuarioState();
}

class _ConfiguracionUsuarioState extends State<ConfiguracionUsuario> {
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    AppTheme.modeNotifier.addListener(_handleThemeChanged);
  }

  @override
  void dispose() {
    AppTheme.modeNotifier.removeListener(_handleThemeChanged);
    super.dispose();
  }

  void _handleThemeChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _showPaymentGatewaysDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.foregroundColor,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentGreenSurfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: AppTheme.accentGreenColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pasarelas de pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Aqui podras conectar y administrar tus metodos de cobro cuando esta configuracion este disponible.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentGreenColor,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required Color borderColor,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _loggingOut = true);

    try {
      await AuthService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.foregroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppTheme.isDark ? 0.4 : 0.06,
              ),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Container(
              padding: const EdgeInsets.only(bottom: 5),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.dividerColor, width: 1.0),
                ),
              ),
              child: Text(
                'Configuración del usuario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Foto de perfil
            ImageAccount(
              imageUrl: widget.user?.imageUrl ?? '',
              fallbackName: widget.user?.name ?? '',
            ),
            const SizedBox(height: 20),

            // Confianza
            _TrustSection(score: widget.user?.trustScore),
            const SizedBox(height: 20),

            // Nombre de usuario
            UsernameAccount(initialValue: widget.user?.name ?? ''),
            const SizedBox(height: 20),

            // Email
            EmailConfiguration(initialValue: widget.user?.email ?? ''),
            const SizedBox(height: 20),

            //Phone Number
            PhoneConfiguration(initialValue: widget.user?.phone ?? ''),
            const SizedBox(height: 20),

            // Agenda
            ContactsConfiguration(),
            SizedBox(height: 20),

            // Social Media
            SocialMediaConfiguration(
              instagramValue: widget.user?.instagram ?? '',
              xValue: widget.user?.xHandle ?? '',
              telegramValue: widget.user?.telegram ?? '',
            ),
            SizedBox(height: 20),

            // Apariencia (light/dark)
            const ThemeSwitcher(),
            const SizedBox(height: 20),

            // Pasarelas de pago
            _buildActionButton(
              label: 'Configurar pasarelas de pago',
              icon: Icons.account_balance_wallet_outlined,
              onTap: _showPaymentGatewaysDialog,
              borderColor: AppTheme.accentGreenColor,
              backgroundColor: AppTheme.accentGreenSurfaceColor,
              foregroundColor: AppTheme.accentGreenColor,
            ),
            const SizedBox(height: 14),

            //Cerrar Sesion
            _buildActionButton(
              label: _loggingOut ? 'Cerrando Sesion...' : 'Cerrar Sesion',
              icon: Icons.logout,
              onTap: _loggingOut ? null : _handleSignOut,
              borderColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.foregroundColor,
              foregroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  final int? score;

  const _TrustSection({required this.score});

  String _label(int? value) {
    if (value == null) return 'Sin datos';
    if (value < 30) return 'Necesita mejorar';
    if (value <= 60) return 'En construccion';
    if (value <= 85) return 'Buena';
    return 'Excelente';
  }

  String _description(int? value) {
    if (value == null) {
      return 'Aun no tenemos suficientes datos para calcular tu nivel de confianza. Completa tu perfil y empieza a operar para construirla.';
    }
    if (value < 30) {
      return 'Tu confianza es baja. Verifica tu perfil, completa tus datos y mantén buenas operaciones para subirla.';
    }
    if (value <= 60) {
      return 'Tu confianza esta en proceso de crecer. Sigue verificando datos y completando tus operaciones.';
    }
    if (value <= 85) {
      return 'Tu reputacion es solida. Mantente activo y cumple con tus tratos para seguir subiendo.';
    }
    return 'Tienes un nivel de confianza excelente. Los demas usuarios te ven como alguien confiable para operar.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.selectedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.foregroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tu confianza',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _label(score),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TrustBar(score: score),
          const SizedBox(height: 10),
          Text(
            _description(score),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
