import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/models/service_model.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/service_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/modal_subtitle.dart';
import 'package:vibe_trade_v1/widgets/modal_title.dart';

Future<ServiceModel?> showServiceModal(
  BuildContext context, {
  required String storeId,
  ServiceModel? initialService,
}) {
  return showDialog<ServiceModel>(
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
              child: ServiceForm(
                storeId: storeId,
                initialService: initialService,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ServiceForm extends StatefulWidget {
  final String storeId;
  final ServiceModel? initialService;

  const ServiceForm({
    super.key,
    required this.storeId,
    this.initialService,
  });

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  late final TextEditingController _serviceTypeController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _risksController;
  late final TextEditingController _includesController;
  late final TextEditingController _excludesController;
  late final TextEditingController _dependenciesController;
  late final TextEditingController _deliveryController;
  late final TextEditingController _warrantyController;
  late final TextEditingController _intellectualPropertyController;

  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  final Set<ProductCurrency> _selectedCurrencies = <ProductCurrency>{};

  bool _hasRisks = false;
  bool _hasDependencies = false;
  bool _hasWarranty = false;

  List<String> _imagePaths = <String>[];

  List<String> _availableCategories = const <String>[];
  bool _loadingCategories = true;
  String? _categoriesError;

  bool _saving = false;

  bool get _isEditing => widget.initialService != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialService;
    _serviceTypeController = TextEditingController(
      text: initial?.serviceType ?? '',
    );
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _risksController = TextEditingController(text: initial?.risks ?? '');
    _includesController = TextEditingController(
      text: initial?.includes ?? '',
    );
    _excludesController = TextEditingController(
      text: initial?.excludes ?? '',
    );
    _dependenciesController = TextEditingController(
      text: initial?.dependencies ?? '',
    );
    _deliveryController = TextEditingController(
      text: initial?.delivery ?? '',
    );
    _warrantyController = TextEditingController(
      text: initial?.warranty ?? '',
    );
    _intellectualPropertyController = TextEditingController(
      text: initial?.intellectualProperty ?? '',
    );

    _selectedCategory = (initial?.category.isNotEmpty ?? false)
        ? initial!.category
        : null;
    _selectedCurrencies.addAll(initial?.acceptedCurrencies ?? const []);

    _hasRisks = initial?.hasRisks ?? false;
    _hasDependencies = initial?.hasDependencies ?? false;
    _hasWarranty = initial?.hasWarranty ?? false;

    _imagePaths = List<String>.from(initial?.imagePaths ?? const <String>[]);

    _loadCategories();
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    _risksController.dispose();
    _includesController.dispose();
    _excludesController.dispose();
    _dependenciesController.dispose();
    _deliveryController.dispose();
    _warrantyController.dispose();
    _intellectualPropertyController.dispose();
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
      final unique = <String>{
        ...categories,
        if (_selectedCategory != null) _selectedCategory!,
      }.toList()..sort();
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

  Future<void> _addImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      _imagePaths = <String>[
        ..._imagePaths,
        for (final file in picked) file.path,
      ];
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths = <String>[
        ..._imagePaths.sublist(0, index),
        ..._imagePaths.sublist(index + 1),
      ];
    });
  }

  Future<void> _save() async {
    final serviceType = _serviceTypeController.text.trim();
    final description = _descriptionController.text.trim();
    final risks = _risksController.text.trim();
    final includes = _includesController.text.trim();
    final excludes = _excludesController.text.trim();
    final dependencies = _dependenciesController.text.trim();
    final delivery = _deliveryController.text.trim();
    final warranty = _warrantyController.text.trim();
    final intellectualProperty = _intellectualPropertyController.text.trim();
    final category = _selectedCategory;

    if (category == null || category.isEmpty) {
      _showError('Selecciona una categoria');
      return;
    }
    if (serviceType.isEmpty) {
      _showError('Indica el tipo de servicio');
      return;
    }
    if (_selectedCurrencies.isEmpty) {
      _showError('Selecciona al menos una moneda aceptada');
      return;
    }
    if (description.isEmpty) {
      _showError('Agrega una descripcion del servicio');
      return;
    }
    if (_hasRisks && risks.isEmpty) {
      _showError('Describe los riesgos del servicio');
      return;
    }
    if (_hasDependencies && dependencies.isEmpty) {
      _showError('Describe las dependencias del servicio');
      return;
    }
    if (_hasWarranty && warranty.isEmpty) {
      _showError('Describe las garantias del servicio');
      return;
    }
    if (_imagePaths.isEmpty) {
      _showError('Agrega al menos una foto del servicio');
      return;
    }

    final currencies = _selectedCurrencies.toList(growable: false);

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final ServiceModel result;
      if (_isEditing) {
        result = await ServiceService.updateService(
          widget.initialService!.id,
          category: category,
          serviceType: serviceType,
          acceptedCurrencies: currencies,
          description: description,
          hasRisks: _hasRisks,
          risks: risks,
          includes: includes,
          excludes: excludes,
          hasDependencies: _hasDependencies,
          dependencies: dependencies,
          delivery: delivery,
          hasWarranty: _hasWarranty,
          warranty: warranty,
          intellectualProperty: intellectualProperty,
          imagePaths: _imagePaths,
        );
      } else {
        result = await ServiceService.createService(
          storeId: widget.storeId,
          category: category,
          serviceType: serviceType,
          acceptedCurrencies: currencies,
          description: description,
          hasRisks: _hasRisks,
          risks: risks,
          includes: includes,
          excludes: excludes,
          hasDependencies: _hasDependencies,
          dependencies: dependencies,
          delivery: delivery,
          hasWarranty: _hasWarranty,
          warranty: warranty,
          intellectualProperty: intellectualProperty,
          imagePaths: _imagePaths,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, result);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Servicio "$serviceType" actualizado'
                : 'Servicio "$serviceType" agregado',
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

  InputDecoration _inputDecoration({String? hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.hintColor),
      isDense: true,
      filled: true,
      prefixIcon: prefix,
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

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_loadingCategories) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Cargando categorias...',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_categoriesError != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.errorSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _categoriesError!,
                style: TextStyle(fontSize: 12, color: AppTheme.errorColor),
              ),
            ),
            TextButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          dropdownColor: AppTheme.foregroundColor,
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          hint: Text(
            'Selecciona una categoria',
            style: TextStyle(fontSize: 13, color: AppTheme.hintColor),
          ),
          items: [
            for (final cat in _availableCategories)
              DropdownMenuItem<String>(
                value: cat,
                child: Text(
                  cat,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final currency in ProductCurrency.allValues)
          _buildCurrencyChip(currency),
      ],
    );
  }

  Widget _buildCurrencyChip(ProductCurrency currency) {
    final selected = _selectedCurrencies.contains(currency);
    return FilterChip(
      label: Text(currency.label),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedCurrencies.add(currency);
          } else {
            _selectedCurrencies.remove(currency);
          }
        });
      },
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppTheme.textPrimary,
      ),
      backgroundColor: AppTheme.inputFillColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String text,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? AppTheme.selectedColor : AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: value
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimary,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_imagePaths.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _imagePaths.length; i++)
                _buildThumbnail(i),
              _buildAddTile(),
            ],
          )
        else
          InkWell(
            onTap: _saving ? null : _addImages,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 130,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.selectedColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 30,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Agregar fotos del servicio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Minimo 1 foto. Puedes elegir varias a la vez.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_imagePaths.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_imagePaths.length} ${_imagePaths.length == 1 ? "foto agregada" : "fotos agregadas"}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail(int index) {
    final path = _imagePaths[index];
    final exists = path.isNotEmpty && File(path).existsSync();
    return Stack(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: AppTheme.inputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: exists
              ? Image.file(File(path), fit: BoxFit.cover)
              : Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textMuted,
                    size: 24,
                  ),
                ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: AppTheme.foregroundColor,
            borderRadius: BorderRadius.circular(999),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _saving ? null : () => _removeImage(index),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTile() {
    return InkWell(
      onTap: _saving ? null : _addImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 86,
        height: 86,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppTheme.selectedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppTheme.primaryColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              'Agregar',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
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
        ModalTitle(text: _isEditing ? 'Editar servicio' : 'Nuevo servicio'),
        const SizedBox(height: 4),
        ModalSubtitle(
          text: _isEditing
              ? 'Actualiza los datos del servicio'
              : 'Define los detalles del servicio que ofreces',
        ),
        const SizedBox(height: 16),

        _label('Categoria', required: true),
        _buildCategorySelector(),
        const SizedBox(height: 14),

        _label('Tipo de servicio', required: true),
        TextField(
          controller: _serviceTypeController,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Ej. Reparacion de electrodomesticos',
          ),
        ),
        const SizedBox(height: 14),

        _label('Monedas aceptadas', required: true),
        _buildCurrencySelector(),
        const SizedBox(height: 14),

        _label('Descripcion del servicio', required: true),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Cuentanos en que consiste el servicio',
          ),
        ),
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.warning_amber_outlined,
          title: 'Riesgos del servicio',
        ),
        const SizedBox(height: 10),
        _buildToggleRow(
          text: 'Configurar riesgos del servicio',
          value: _hasRisks,
          onChanged: (value) => setState(() => _hasRisks = value),
          icon: Icons.warning_amber_outlined,
        ),
        if (_hasRisks) ...[
          const SizedBox(height: 10),
          _label('Riesgos', required: true),
          TextField(
            controller: _risksController,
            maxLines: 3,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: _inputDecoration(
              hint:
                  'Ej. Riesgos de corte electrico, posibles dañios secundarios.',
            ),
          ),
        ],
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.list_alt_outlined,
          title: 'Alcance del servicio',
        ),
        const SizedBox(height: 10),
        _label('Que incluye'),
        TextField(
          controller: _includesController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Lo que esta dentro del servicio.',
          ),
        ),
        const SizedBox(height: 12),
        _label('Que no incluye'),
        TextField(
          controller: _excludesController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Lo que queda fuera del servicio.',
          ),
        ),
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.account_tree_outlined,
          title: 'Dependencias',
        ),
        const SizedBox(height: 10),
        _buildToggleRow(
          text: 'Configurar dependencias',
          value: _hasDependencies,
          onChanged: (value) => setState(() => _hasDependencies = value),
          icon: Icons.account_tree_outlined,
        ),
        if (_hasDependencies) ...[
          const SizedBox(height: 10),
          _label('Dependencias', required: true),
          TextField(
            controller: _dependenciesController,
            maxLines: 3,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: _inputDecoration(
              hint:
                  'Ej. Requiere acceso a la red electrica, herramientas del cliente.',
            ),
          ),
        ],
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.local_shipping_outlined,
          title: 'Entrega del servicio',
        ),
        const SizedBox(height: 10),
        _label('Que se entrega'),
        TextField(
          controller: _deliveryController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Ej. Reporte tecnico, equipo funcionando, factura.',
          ),
        ),
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.verified_user_outlined,
          title: 'Garantias',
        ),
        const SizedBox(height: 10),
        _buildToggleRow(
          text: 'Ofrezco garantias',
          value: _hasWarranty,
          onChanged: (value) => setState(() => _hasWarranty = value),
          icon: Icons.verified_user_outlined,
        ),
        if (_hasWarranty) ...[
          const SizedBox(height: 10),
          _label('Garantias', required: true),
          TextField(
            controller: _warrantyController,
            maxLines: 3,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: _inputDecoration(
              hint: 'Ej. Garantia de 30 dias en piezas y mano de obra.',
            ),
          ),
        ],
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.copyright_outlined,
          title: 'Propiedad intelectual',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _intellectualPropertyController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint:
                'Ej. Los entregables son propiedad del cliente. El proveedor conserva derechos sobre las metodologias.',
          ),
        ),
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.photo_library_outlined,
          title: 'Fotos del servicio',
        ),
        const SizedBox(height: 10),
        _buildImagesGallery(),
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
                'Cancelar',
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
                    : 'Guardar servicio',
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
