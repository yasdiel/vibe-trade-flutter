import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/product_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/modal_subtitle.dart';
import 'package:vibe_trade_v1/widgets/modal_title.dart';

Future<ProductModel?> showProductModal(
  BuildContext context, {
  required String storeId,
  ProductModel? initialProduct,
}) {
  return showDialog<ProductModel>(
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
              child: ProductForm(
                storeId: storeId,
                initialProduct: initialProduct,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ProductForm extends StatefulWidget {
  final String storeId;
  final ProductModel? initialProduct;

  const ProductForm({
    super.key,
    required this.storeId,
    this.initialProduct,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _versionController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _mainBenefitController;
  late final TextEditingController _technicalFeaturesController;
  late final TextEditingController _taxesShippingInstallController;
  late final TextEditingController _stockController;
  late final TextEditingController _warrantyAndReturnsController;
  late final TextEditingController _includedContentController;
  late final TextEditingController _usageConditionsController;
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  ProductCondition? _selectedCondition;
  ProductCurrency? _selectedPriceCurrency;
  final Set<ProductCurrency> _selectedCurrencies = <ProductCurrency>{};

  List<String> _availableCategories = const <String>[];
  bool _loadingCategories = true;
  String? _categoriesError;

  File? _pendingImage;
  String _savedImagePath = '';
  bool _saving = false;

  bool get _isEditing => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProduct;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _versionController = TextEditingController(text: initial?.version ?? '');
    _priceController = TextEditingController(
      text: initial != null ? _formatPrice(initial.price) : '',
    );
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _mainBenefitController = TextEditingController(
      text: initial?.mainBenefit ?? '',
    );
    _technicalFeaturesController = TextEditingController(
      text: initial?.technicalFeatures ?? '',
    );
    _taxesShippingInstallController = TextEditingController(
      text: initial?.taxesShippingInstall ?? '',
    );
    _stockController = TextEditingController(
      text: initial?.stock != null ? initial!.stock.toString() : '',
    );
    _warrantyAndReturnsController = TextEditingController(
      text: initial?.warrantyAndReturns ?? '',
    );
    _includedContentController = TextEditingController(
      text: initial?.includedContent ?? '',
    );
    _usageConditionsController = TextEditingController(
      text: initial?.usageConditions ?? '',
    );
    _selectedCategory = (initial?.category.isNotEmpty ?? false)
        ? initial!.category
        : null;
    _selectedCondition = initial?.condition;
    _selectedCurrencies.addAll(initial?.acceptedCurrencies ?? const []);
    _selectedPriceCurrency =
        initial?.priceCurrency ??
        (initial != null && initial.acceptedCurrencies.isNotEmpty
            ? initial.acceptedCurrencies.first
            : null);
    if (_selectedPriceCurrency != null) {
      _selectedCurrencies.add(_selectedPriceCurrency!);
    }
    _savedImagePath = initial?.imagePath ?? '';
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _versionController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _mainBenefitController.dispose();
    _technicalFeaturesController.dispose();
    _taxesShippingInstallController.dispose();
    _stockController.dispose();
    _warrantyAndReturnsController.dispose();
    _includedContentController.dispose();
    _usageConditionsController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
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

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _pendingImage = File(picked.path));
  }

  void _clearPendingImage() {
    setState(() => _pendingImage = null);
  }

  void _clearSavedImage() {
    setState(() {
      _pendingImage = null;
      _savedImagePath = '';
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final version = _versionController.text.trim();
    final priceText = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(priceText);
    final description = _descriptionController.text.trim();
    final mainBenefit = _mainBenefitController.text.trim();
    final technicalFeatures = _technicalFeaturesController.text.trim();
    final taxesShippingInstall = _taxesShippingInstallController.text.trim();
    final stockText = _stockController.text.trim();
    final warrantyAndReturns = _warrantyAndReturnsController.text.trim();
    final includedContent = _includedContentController.text.trim();
    final usageConditions = _usageConditionsController.text.trim();
    final category = _selectedCategory;
    final condition = _selectedCondition;
    final priceCurrency = _selectedPriceCurrency;
    final currenciesSet = <ProductCurrency>{
      if (priceCurrency != null) priceCurrency,
      ..._selectedCurrencies,
    };
    final currencies = currenciesSet.toList(growable: false);

    if (category == null || category.isEmpty) {
      _showError('Selecciona una categoria');
      return;
    }
    if (name.isEmpty) {
      _showError('El nombre del producto es obligatorio');
      return;
    }
    if (version.isEmpty) {
      _showError('Indica la version o modelo');
      return;
    }
    if (price == null || price < 0) {
      _showError('Ingresa un precio valido');
      return;
    }
    if (priceCurrency == null) {
      _showError('Selecciona la moneda del precio');
      return;
    }
    if (condition == null) {
      _showError('Selecciona el estado del producto');
      return;
    }
    if (currencies.isEmpty) {
      _showError('Selecciona al menos una moneda aceptada');
      return;
    }

    int? stock;
    if (stockText.isNotEmpty) {
      final parsed = int.tryParse(stockText);
      if (parsed == null || parsed < 0) {
        _showError('El stock debe ser un numero entero igual o mayor que 0');
        return;
      }
      stock = parsed;
    }

    final imagePath = _pendingImage?.path ?? _savedImagePath;

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final ProductModel result;
      if (_isEditing) {
        result = await ProductService.updateProduct(
          widget.initialProduct!.id,
          name: name,
          category: category,
          version: version,
          price: price,
          priceCurrency: priceCurrency,
          condition: condition,
          acceptedCurrencies: currencies,
          description: description,
          mainBenefit: mainBenefit,
          technicalFeatures: technicalFeatures,
          imagePath: imagePath,
          taxesShippingInstall: taxesShippingInstall,
          stock: stock,
          warrantyAndReturns: warrantyAndReturns,
          includedContent: includedContent,
          usageConditions: usageConditions,
        );
      } else {
        result = await ProductService.createProduct(
          storeId: widget.storeId,
          name: name,
          category: category,
          version: version,
          price: price,
          priceCurrency: priceCurrency,
          condition: condition,
          acceptedCurrencies: currencies,
          description: description,
          mainBenefit: mainBenefit,
          technicalFeatures: technicalFeatures,
          imagePath: imagePath,
          taxesShippingInstall: taxesShippingInstall,
          stock: stock,
          warrantyAndReturns: warrantyAndReturns,
          includedContent: includedContent,
          usageConditions: usageConditions,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, result);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Producto "$name" actualizado'
                : 'Producto "$name" agregado',
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

  Widget _buildSectionHeader({required IconData icon, required String title}) {
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

  Widget _buildConditionSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final condition in ProductCondition.values)
          ChoiceChip(
            label: Text(condition.label),
            selected: _selectedCondition == condition,
            onSelected: (selected) {
              setState(
                () => _selectedCondition = selected ? condition : null,
              );
            },
            selectedColor: AppTheme.primaryColor,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _selectedCondition == condition
                  ? Colors.white
                  : AppTheme.textPrimary,
            ),
            backgroundColor: AppTheme.inputFillColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: _selectedCondition == condition
                    ? AppTheme.primaryColor
                    : Colors.transparent,
              ),
            ),
            showCheckmark: false,
          ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: _inputDecoration(hint: '0.00'),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.inputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProductCurrency>(
              value: _selectedPriceCurrency,
              dropdownColor: AppTheme.foregroundColor,
              hint: Text(
                'Moneda',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.hintColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
              items: [
                for (final currency in ProductCurrency.allValues)
                  DropdownMenuItem<ProductCurrency>(
                    value: currency,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currency.symbol,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currency.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedPriceCurrency = value;
                  _selectedCurrencies.add(value);
                });
              },
            ),
          ),
        ),
      ],
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
    final isPriceCurrency = _selectedPriceCurrency == currency;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currency.label),
          if (isPriceCurrency) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.push_pin,
              size: 11,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ],
        ],
      ),
      selected: selected,
      onSelected: isPriceCurrency
          ? null
          : (value) {
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
      tooltip: isPriceCurrency
          ? 'Moneda del precio (no se puede quitar)'
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final pending = _pendingImage;
    final savedPath = _savedImagePath;
    final hasPending = pending != null;
    final hasSaved = savedPath.isNotEmpty && File(savedPath).existsSync();

    Widget content;
    if (hasPending) {
      content = Image.file(
        pending,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
      );
    } else if (hasSaved) {
      content = Image.file(
        File(savedPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
      );
    } else {
      content = Container(
        height: 140,
        width: double.infinity,
        color: AppTheme.selectedColor,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 32,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 6),
            Text(
              'Sin imagen',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: content,
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            color: AppTheme.foregroundColor,
            borderRadius: BorderRadius.circular(999),
            elevation: 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _saving ? null : _pickImage,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_search,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasPending || hasSaved ? 'Cambiar' : 'Elegir',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasPending)
          Positioned(
            left: 8,
            bottom: 8,
            child: Material(
              color: AppTheme.foregroundColor,
              borderRadius: BorderRadius.circular(999),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _saving ? null : _clearPendingImage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Descartar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (hasSaved)
          Positioned(
            left: 8,
            bottom: 8,
            child: Material(
              color: AppTheme.foregroundColor,
              borderRadius: BorderRadius.circular(999),
              elevation: 1,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _saving ? null : _clearSavedImage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Quitar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModalTitle(
          text: _isEditing ? 'Editar producto' : 'Nuevo producto',
        ),
        const SizedBox(height: 4),
        ModalSubtitle(
          text: _isEditing
              ? 'Actualiza los datos del producto'
              : 'Completa los datos para agregarlo a tu catalogo',
        ),
        const SizedBox(height: 16),

        _label('Imagen'),
        _buildImagePreview(),
        const SizedBox(height: 14),

        _label('Categoria', required: true),
        _buildCategorySelector(),
        const SizedBox(height: 14),

        _label('Nombre del producto', required: true),
        TextField(
          controller: _nameController,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(hint: 'Ej. iPhone 13'),
        ),
        const SizedBox(height: 14),

        _label('Version o modelo', required: true),
        TextField(
          controller: _versionController,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(hint: 'Ej. 128GB Negro'),
        ),
        const SizedBox(height: 14),

        _label('Precio', required: true),
        _buildPriceRow(),
        const SizedBox(height: 14),

        _label('Estado', required: true),
        _buildConditionSelector(),
        const SizedBox(height: 14),

        _label('Monedas aceptadas', required: true),
        _buildCurrencySelector(),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.selectedColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'Los siguientes campos son opcionales',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _label('Descripcion breve'),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Cuentanos los detalles del producto',
          ),
        ),
        const SizedBox(height: 14),

        _label('Beneficio principal'),
        TextField(
          controller: _mainBenefitController,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Lo que mas destaca de este producto',
          ),
        ),
        const SizedBox(height: 14),

        _label('Caracteristicas tecnicas'),
        TextField(
          controller: _technicalFeaturesController,
          maxLines: 4,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Especificaciones tecnicas, materiales, etc.',
          ),
        ),
        const SizedBox(height: 18),

        _buildSectionHeader(
          icon: Icons.local_offer_outlined,
          title: 'Detalles comerciales',
        ),
        const SizedBox(height: 14),

        _label('Disponibilidad / stock'),
        TextField(
          controller: _stockController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint: 'Cantidad de unidades disponibles (vacio = consultar)',
            prefix: Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 14),

        _label('Impuestos, envio o instalacion (si aplica)'),
        TextField(
          controller: _taxesShippingInstallController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint:
                'Ej. IVA incluido. Envio nacional 5 EUR. Instalacion gratuita en zona urbana.',
          ),
        ),
        const SizedBox(height: 14),

        _label('Garantia y devolucion'),
        TextField(
          controller: _warrantyAndReturnsController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint:
                'Ej. Garantia oficial 12 meses. Devolucion gratuita los primeros 7 dias.',
          ),
        ),
        const SizedBox(height: 14),

        _label('Contenido incluido'),
        TextField(
          controller: _includedContentController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint:
                'Que se entrega con el producto. Ej. unidad principal, cargador, manual, garantia.',
          ),
        ),
        const SizedBox(height: 14),

        _label('Condiciones de uso'),
        TextField(
          controller: _usageConditionsController,
          maxLines: 3,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: _inputDecoration(
            hint:
                'Restricciones, requisitos o recomendaciones de uso del producto.',
          ),
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
                    : 'Guardar producto',
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
