import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/auth_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/instagram_widget.dart';
import 'package:vibe_trade_v1/widgets/accountConfiguration/telegram_widget.dart';
import 'package:vibe_trade_v1/widgets/modal_subtitle.dart';
import 'package:vibe_trade_v1/widgets/modal_title.dart';
import 'package:vibe_trade_v1/widgets/x_widget.dart';

class SocialMediaConfiguration extends StatefulWidget {
  final String instagramValue;
  final String xValue;
  final String telegramValue;

  const SocialMediaConfiguration({
    super.key,
    this.instagramValue = '',
    this.xValue = '',
    this.telegramValue = '',
  });

  @override
  State<SocialMediaConfiguration> createState() =>
      _SocialMediaConfigurationState();
}

class _SocialMediaConfigurationState extends State<SocialMediaConfiguration> {
  late String _instagramValue;
  late String _xValue;
  late String _telegramValue;

  @override
  void initState() {
    super.initState();
    _instagramValue = widget.instagramValue;
    _xValue = widget.xValue;
    _telegramValue = widget.telegramValue;
  }

  @override
  void didUpdateWidget(covariant SocialMediaConfiguration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instagramValue != widget.instagramValue ||
        oldWidget.xValue != widget.xValue ||
        oldWidget.telegramValue != widget.telegramValue) {
      setState(() {
        _instagramValue = widget.instagramValue;
        _xValue = widget.xValue;
        _telegramValue = widget.telegramValue;
      });
    }
  }

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
            InstagramWidget(initialValue: _instagramValue),
          ],
        ),
      ),
    ).then((_) => _syncValuesFromSession());
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
              XWidget(initialValue: _xValue),
            ],
          ),
        ),
      ),
    ).then((_) => _syncValuesFromSession());
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
              TelegramWidget(initialValue: _telegramValue),
            ],
          ),
        ),
      ),
    ).then((_) => _syncValuesFromSession());
  }

  Future<void> _syncValuesFromSession() async {
    final user = AuthService.currentUserNotifier.value ??
        await AuthService.getSavedUser();
    if (!mounted || user == null) {
      return;
    }
    setState(() {
      _instagramValue = user.instagram;
      _xValue = user.xHandle;
      _telegramValue = user.telegram;
    });
  }

  bool get _hasSavedNetworks =>
      _instagramValue.trim().isNotEmpty ||
      _xValue.trim().isNotEmpty ||
      _telegramValue.trim().isNotEmpty;

  Future<void> _deleteNetwork(String type) async {
    try {
      if (type == 'instagram') {
        await AuthService.updateUserProfile(instagram: '');
      } else if (type == 'x') {
        await AuthService.updateUserProfile(xAccount: '');
      } else if (type == 'telegram') {
        await AuthService.updateUserProfile(telegram: '');
      }
      await _syncValuesFromSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Red social eliminada')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showSavedNetworkModal({
    required String type,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(10),
        ),
        shadowColor: AppTheme.primaryColor,
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalTitle(text: label),
              const SizedBox(height: 6),
              ModalSubtitle(text: value),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _deleteNetwork(type);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                    child: const Text('Eliminar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor, width: 1),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    child: const Text(
                      'Editar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
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
          children: [
            Icon(
              Icons.person_outline,
              size: 16,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Multi-cuenta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
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
        if (_hasSavedNetworks) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.subtleSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redes guardadas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_instagramValue.trim().isNotEmpty)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text('Instagram'),
                    subtitle: Text(_instagramValue.trim()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSavedNetworkModal(
                      type: 'instagram',
                      label: 'Instagram',
                      value: _instagramValue.trim(),
                      onEdit: _showInstagramModal,
                    ),
                  ),
                if (_xValue.trim().isNotEmpty)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text('X'),
                    subtitle: Text(_xValue.trim()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSavedNetworkModal(
                      type: 'x',
                      label: 'X',
                      value: _xValue.trim(),
                      onEdit: _showXModal,
                    ),
                  ),
                if (_telegramValue.trim().isNotEmpty)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.send,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text('Telegram'),
                    subtitle: Text(_telegramValue.trim()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showSavedNetworkModal(
                      type: 'telegram',
                      label: 'Telegram',
                      value: _telegramValue.trim(),
                      onEdit: _showTelegramModal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
