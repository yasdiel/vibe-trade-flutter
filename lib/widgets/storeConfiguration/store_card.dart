import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class StoreCard extends StatefulWidget {
  final StoreModel store;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StoreCard({
    super.key,
    required this.store,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<StoreCard> {
  final ImagePicker _picker = ImagePicker();
  File? _pendingImage;
  bool _saving = false;

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _pendingImage = File(picked.path));
  }

  Future<void> _saveImage() async {
    if (_pendingImage == null) {
      await _pickImage();
      return;
    }
    setState(() => _saving = true);
    try {
      await StoreService.updateStore(
        widget.store.id,
        imagePath: _pendingImage!.path,
      );
      if (!mounted) return;
      setState(() => _pendingImage = null);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de la tienda actualizada')),
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _discardImage() {
    setState(() => _pendingImage = null);
  }

  String _formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${pad(date.day)}/${pad(date.month)}/${date.year}';
  }

  Color _trustColor(int value) {
    if (value < 30) return AppTheme.errorColor;
    if (value <= 60) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  Widget _buildAvatar() {
    final pending = _pendingImage;
    final savedPath = widget.store.imagePath;
    final fallbackLetter = widget.store.name.trim().isNotEmpty
        ? widget.store.name.trim()[0].toUpperCase()
        : 'T';

    Widget child;
    if (pending != null) {
      child = Image.file(pending, width: 64, height: 64, fit: BoxFit.cover);
    } else if (savedPath.isNotEmpty && File(savedPath).existsSync()) {
      child = Image.file(
        File(savedPath),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      );
    } else {
      child = _fallbackAvatar(fallbackLetter);
    }

    return GestureDetector(
      onTap: _saving ? null : _pickImage,
      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: child),
    );
  }

  Widget _fallbackAvatar(String letter) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    final isVerified = widget.store.isVerified;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVerified
            ? AppTheme.successSurface
            : AppTheme.surfaceMutedColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVerified
              ? AppTheme.successColor.withValues(alpha: 0.5)
              : AppTheme.dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.error_outline,
            size: 12,
            color: isVerified ? AppTheme.successColor : AppTheme.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verificada' : 'No verificada',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isVerified ? AppTheme.successColor : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final transportText = widget.store.hasOwnTransport
        ? 'Con transporte'
        : 'Sin transporte';
    final transportColor = widget.store.hasOwnTransport
        ? AppTheme.primaryColor
        : AppTheme.textMuted;

    return Row(
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 12,
          color: AppTheme.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(widget.store.createdAt),
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 10),
        Icon(Icons.local_shipping_outlined, size: 12, color: transportColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            transportText,
            style: TextStyle(
              fontSize: 12,
              color: transportColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBar() {
    final score = widget.store.trustScore.clamp(0, 100);
    final color = _trustColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confianza de la tienda',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: score / 100,
              backgroundColor: AppTheme.surfaceMutedColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onOpen,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.store.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildVerifiedBadge(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildMetaRow(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Editar tienda',
                    onPressed: _saving ? null : widget.onEdit,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar tienda',
                    onPressed: _saving ? null : widget.onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTrustBar(),
              const SizedBox(height: 12),
              if (widget.store.description.isNotEmpty) ...[
                Text(
                  widget.store.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.selectedColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gestiona productos y servicios desde el catalogo de la tienda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveImage,
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 16),
                      label: Text(
                        _saving
                            ? 'Guardando...'
                            : _pendingImage != null
                            ? 'Guardar foto'
                            : 'Seleccionar foto',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !_saving && _pendingImage != null
                          ? _discardImage
                          : null,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Descartar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _pendingImage != null
                            ? AppTheme.textPrimary
                            : AppTheme.textMuted.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: _pendingImage != null
                              ? AppTheme.textSecondary
                              : AppTheme.dividerColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
}
