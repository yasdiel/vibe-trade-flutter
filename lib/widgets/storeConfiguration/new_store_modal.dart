import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/modal_subtitle.dart';
import 'package:vibe_trade_v1/widgets/modal_title.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/location_picker_screen.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_category_selector.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_location_preview.dart';

Future<StoreModel?> showNewStoreModal(
  BuildContext context, {
  StoreModel? initialStore,
}) {
  return showDialog<StoreModel>(
    context: context,
    builder: (context) {
      final size = MediaQuery.of(context).size;
      final isWide = size.width >= 720;
      return Dialog(
        backgroundColor: AppTheme.foregroundColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: isWide
            ? const EdgeInsets.symmetric(horizontal: 40, vertical: 24)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 540 : double.infinity,
            maxHeight: size.height * 0.92,
          ),
          child: Padding(
            padding: EdgeInsets.all(isWide ? 22 : 18),
            child: SingleChildScrollView(
              child: NewStoreForm(initialStore: initialStore),
            ),
          ),
        ),
      );
    },
  );
}

class NewStoreForm extends StatefulWidget {
  final StoreModel? initialStore;

  const NewStoreForm({super.key, this.initialStore});

  @override
  State<NewStoreForm> createState() => _NewStoreFormState();
}

class _NewStoreFormState extends State<NewStoreForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _websiteController;

  List<String> _availableCategories = const <String>[];
  late final List<String> _selectedCategories;
  late bool _hasOwnTransport;
  LatLng? _selectedLocation;

  bool _loadingCategories = true;
  String? _categoriesError;
  bool _saving = false;

  bool get _isEditing => widget.initialStore != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStore;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _websiteController = TextEditingController(text: initial?.website ?? '');
    _selectedCategories = <String>[...?initial?.categories];
    _hasOwnTransport = initial?.hasOwnTransport ?? false;
    if (initial != null && initial.hasLocation) {
      _selectedLocation = LatLng(initial.latitude!, initial.longitude!);
    }
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
      final unique = <String>{...categories, ..._selectedCategories}.toList();
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
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
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
      final StoreModel result;
      if (_isEditing) {
        result = await StoreService.updateStore(
          widget.initialStore!.id,
          name: name,
          description: description,
          categories: List<String>.unmodifiable(_selectedCategories),
          hasOwnTransport: _hasOwnTransport,
          website: website,
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          clearLocation: _selectedLocation == null,
        );
      } else {
        result = await StoreService.createStore(
          name: name,
          description: description,
          categories: List<String>.unmodifiable(_selectedCategories),
          hasOwnTransport: _hasOwnTransport,
          website: website,
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, result);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Tienda "$name" actualizada' : 'Tienda "$name" creada',
          ),
        ),
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
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.hintColor),
      isDense: true,
      filled: true,
      fillColor: AppTheme.inputFillColor,
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
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
        ModalTitle(text: _isEditing ? 'Editar Tienda' : 'Nueva Tienda'),
        const SizedBox(height: 4),
        ModalSubtitle(
          text: _isEditing
              ? 'Actualiza los datos de tu tienda'
              : 'Aqui pon lo que quieras',
        ),
        const SizedBox(height: 16),

        _buildLabel('Nombre de la tienda'),
        TextField(
          controller: _nameController,
          style: TextStyle(color: AppTheme.textPrimary),
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
          style: TextStyle(color: AppTheme.textPrimary),
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
            Expanded(
              child: Text(
                'Mi tienda tiene transporte propio',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        _buildLabel('Sitio web (opcional)'),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          style: TextStyle(color: AppTheme.textPrimary),
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
                _saving
                    ? 'Guardando...'
                    : _isEditing
                    ? 'Actualizar'
                    : 'Guardar',
                style: const TextStyle(
                  color: Colors.white,
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
