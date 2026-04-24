import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/instagram_widget.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/telegram_widget.dart';
import 'package:vibe_trade_v1/widgets/modal_subtitle.dart';
import 'package:vibe_trade_v1/widgets/modal_title.dart';
import 'package:vibe_trade_v1/widgets/x_widget.dart';

class SocialMediaConfiguration extends StatefulWidget {
  const SocialMediaConfiguration({super.key});

  @override
  State<SocialMediaConfiguration> createState() =>
      _SocialMediaConfigurationState();
}

class _SocialMediaConfigurationState extends State<SocialMediaConfiguration> {
  void _showInstagramModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        shadowColor: AppTheme.primaryColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ModalTitle(text: 'Conectar Instagram'),
            ModalSubtitle(
              text: 'Puedes guardar tu usuario usuario o un enlace a tu perfil',
            ),
            SizedBox(height: 15),
            InstagramWidget(),
          ],
        ),
      ),
    );
  }

  void _showXModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        shadowColor: AppTheme.primaryColor,
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalTitle(text: 'Conectar X'),
              ModalSubtitle(text: 'Tu @ de X o el enlace a tu perfil'),
              SizedBox(height: 15),
              XWidget(),
            ],
          ),
        ),
      ),
    );
  }

  void _showTelegramModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        shadowColor: AppTheme.primaryColor,
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalTitle(text: 'Conectar Telegram'),
              ModalSubtitle(text: 'Usuario publico (sin @) o https://t.me/...'),
              SizedBox(height: 15),
              TelegramWidget(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Icon(Icons.person_outline, size: 16, color: Colors.black54),
            SizedBox(width: 6),
            Text(
              'Multi-cuenta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.foregroundColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: _showInstagramModal,

              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Instagram',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight(400),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.foregroundColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: _showXModal,

              child: Row(
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'X',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight(400),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.foregroundColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: _showTelegramModal,

              child: Row(
                children: [
                  Icon(Icons.send, size: 14, color: AppTheme.primaryColor),
                  SizedBox(width: 5),
                  Text(
                    'Telegram',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight(400),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
