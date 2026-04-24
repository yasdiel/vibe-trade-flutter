import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';

class ImageAccount extends StatefulWidget {
  const ImageAccount({super.key});

  @override
  State<ImageAccount> createState() => _ImageAccountState();
}

class _ImageAccountState extends State<ImageAccount> {
  File? _imagenSeleccionada;
  File? _imagenGuardada;
  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = File(imagen.path);
      });
    }
  }

  void _guardarFoto() {
    if (_imagenSeleccionada != null) {
      setState(() {
        _imagenGuardada = _imagenSeleccionada;
        _imagenSeleccionada = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto guardada correctamente')),
      );
    }
  }

  void _descartarFoto() {
    setState(() {
      _imagenSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final File? imagenActual = _imagenSeleccionada ?? _imagenGuardada;
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _seleccionarImagen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imagenActual != null
                  ? Image.file(
                      imagenActual,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF5B6EF5), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'U',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Label foto de perfil
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.image_outlined, size: 16, color: Colors.black54),
              SizedBox(width: 4),
              Text(
                'Foto de perfil',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Descripción
        const Center(
          child: Text(
            'Elegí una imagen desde tu dispositivo y guardala con el botón (vista previa local con URL blob).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ),
        const SizedBox(height: 16),

        // Botones Guardar foto / Descartar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _imagenSeleccionada != null
                  ? _guardarFoto
                  : _seleccionarImagen,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Guardar foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.foregroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _imagenSeleccionada != null ? _descartarFoto : null,
              child: Text(
                'Descartar',
                style: TextStyle(
                  color: _imagenSeleccionada != null
                      ? Colors.black54
                      : Colors.black26,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
