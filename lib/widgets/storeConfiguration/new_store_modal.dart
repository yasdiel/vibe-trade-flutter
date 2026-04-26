import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/modal_subtitle.dart';
import 'package:vibe_trade_v1/widgets/modal_title.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/location_picker_screen.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_category_selector.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_location_preview.dart';

Future<void> showNewStoreModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
      ),
      shadowColor: AppTheme.primaryColor,
      content: SizedBox(
        width: 360,
        child: const SingleChildScrollView(child: NewStoreForm()),
      ),
    ),
  );
}

class NewStoreForm extends StatefulWidget {
  const NewStoreForm({super.key});

  @override
  State<NewStoreForm> createState() => _NewStoreFormState();
}

class _NewStoreFormState extends State<NewStoreForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  List<String> _availableCategories = const <String>[];
  final List<String> _selectedCategories = <String>[];
  bool _hasOwnTransport = false;
  LatLng? _selectedLocation;

  bool _loadingCategories = true;
  String? _categoriesError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = await MarketService.getCatalogCategories();
      if (!mounted) return;
      // Deduplicate to avoid DropdownButton assertion errors when the API
      // accidentally returns repeated values.
      final unique = <String>{...categories}.toList();
      setState(() {
        _availableCategories = unique;
        _loadingCategories = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categoriesError = error.toString().replaceFirst('Exception: ', '');
        _loadingCategories = false;
      });
    }
  }

  void _addCategory(String? value) {
    if (value == null || value.isEmpty) return;
    if (_selectedCategories.contains(value)) return;
    setState(() => _selectedCategories.add(value));
  }

  void _removeCategory(String value) {
    setState(() => _selectedCategories.remove(value));
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng?>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _selectedLocation = result);
  }

  bool _isValidWebsite(String value) {
    if (value.isEmpty) return true;
    final pattern = RegExp(
      r'^(https?:\/\/)?([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,})(\/[\w\-./?%&=]*)?$',
    );
    return pattern.hasMatch(value);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final website = _websiteController.text.trim();

    if (name.isEmpty) {
      _showError('El nombre de la tienda es obligatorio');
      return;
    }
    if (_selectedCategories.isEmpty) {
      _showError('Selecciona al menos una categoria');
      return;
    }
    if (description.isEmpty) {
      _showError('La descripcion es obligatoria');
      return;
    }
    if (!_isValidWebsite(website)) {
      _showError('El sitio web no es valido');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      // TODO: Replace with backend create-store endpoint when available.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tienda "$name" creada')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
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
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ModalTitle(text: 'Nueva Tienda'),
        const SizedBox(height: 4),
        const ModalSubtitle(text: 'Aqui pon lo que quieras'),
        const SizedBox(height: 16),

        _buildLabel('Nombre de la tienda'),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration(hint: 'Ej. Mi tienda'),
        ),
        const SizedBox(height: 14),

        _buildLabel('Categorias'),
        StoreCategorySelector(
          loading: _loadingCategories,
          error: _categoriesError,
          availableCategories: _availableCategories,
          selectedCategories: _selectedCategories,
          onCategorySelected: _addCategory,
          onCategoryRemoved: _removeCategory,
          onRetry: _loadCategories,
        ),
        const SizedBox(height: 14),

        _buildLabel('Descripcion de productos y servicios'),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: _inputDecoration(
            hint: 'Cuentanos que ofreces en tu tienda',
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Checkbox(
              value: _hasOwnTransport,
              activeColor: AppTheme.primaryColor,
              onChanged: (value) =>
                  setState(() => _hasOwnTransport = value ?? false),
            ),
            const Expanded(
              child: Text(
                'Mi tienda tiene transporte propio',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        _buildLabel('Sitio web (opcional)'),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: _inputDecoration(hint: 'https://mitienda.com'),
        ),
        const SizedBox(height: 14),

        _buildLabel('Ubicacion (opcional)'),
        if (_selectedLocation == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: Icon(
                Icons.location_on_outlined,
                color: AppTheme.primaryColor,
              ),
              label: Text(
                'Agregar ubicacion',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          StoreLocationPreview(
            location: _selectedLocation!,
            onTap: _pickLocation,
            onClear: () => setState(() => _selectedLocation = null),
          ),

        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.foregroundColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 5),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor, width: 1),
              ),
              onPressed: _saving ? null : _save,
              child: Text(
                _saving ? 'Guardando...' : 'Guardar',
                style: TextStyle(
                  color: AppTheme.foregroundColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
