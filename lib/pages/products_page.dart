import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/services/product_service.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/productConfiguration/new_product_modal.dart';
import 'package:vibe_trade_v1/widgets/productConfiguration/product_card.dart';

enum ProductSortOrder { none, priceAsc, priceDesc }

extension ProductSortOrderLabel on ProductSortOrder {
  String get label {
    switch (this) {
      case ProductSortOrder.none:
        return 'Sin orden';
      case ProductSortOrder.priceAsc:
        return 'Precio: menor a mayor';
      case ProductSortOrder.priceDesc:
        return 'Precio: mayor a menor';
    }
  }
}

class ProductsPage extends StatelessWidget {
  final String storeId;

  const ProductsPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StoreModel>>(
      valueListenable: StoreService.storesNotifier,
      builder: (context, stores, _) {
        StoreModel? matched;
        for (final candidate in stores) {
          if (candidate.id == storeId) {
            matched = candidate;
            break;
          }
        }

        if (matched == null) {
          return Scaffold(
            backgroundColor: AppTheme.appBgColor,
            appBar: AppBar(
              backgroundColor: AppTheme.foregroundColor,
              foregroundColor: AppTheme.textPrimary,
              elevation: 1,
              title: const Text('Catalogo'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'La tienda ya no existe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          );
        }

        final StoreModel store = matched;

        return ValueListenableBuilder<List<ProductModel>>(
          valueListenable: ProductService.productsNotifier,
          builder: (context, allProducts, _) {
            final products = allProducts
                .where((p) => p.storeId == store.id)
                .toList(growable: false);
            return _ProductsScaffold(store: store, products: products);
          },
        );
      },
    );
  }
}

class _ProductsScaffold extends StatefulWidget {
  final StoreModel store;
  final List<ProductModel> products;

  const _ProductsScaffold({required this.store, required this.products});

  @override
  State<_ProductsScaffold> createState() => _ProductsScaffoldState();
}

class _ProductsScaffoldState extends State<_ProductsScaffold> {
  final TextEditingController _searchController = TextEditingController();
  String _nameQuery = '';
  String? _categoryFilter;
  final Set<ProductCondition> _conditionFilters = <ProductCondition>{};
  final Set<ProductCurrency> _currencyFilters = <ProductCurrency>{};
  ProductSortOrder _sortOrder = ProductSortOrder.none;
  RangeValues? _priceRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate(BuildContext context) async {
    await showProductModal(context, storeId: widget.store.id);
  }

  Future<void> _openEdit(BuildContext context, ProductModel product) async {
    await showProductModal(
      context,
      storeId: widget.store.id,
      initialProduct: product,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar producto'),
        content: Text(
          'Seguro que quieres eliminar "${product.name}"? Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ProductService.deleteProduct(product.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto "${product.name}" eliminado')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _nameQuery = '';
      _categoryFilter = null;
      _conditionFilters.clear();
      _currencyFilters.clear();
      _sortOrder = ProductSortOrder.none;
      _priceRange = null;
    });
  }

  List<String> get _availableCategories {
    final set = <String>{};
    for (final p in widget.products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  Set<ProductCondition> get _availableConditions {
    final set = <ProductCondition>{};
    for (final p in widget.products) {
      if (p.condition != null) set.add(p.condition!);
    }
    return set;
  }

  Set<ProductCurrency> get _availableCurrencies {
    final set = <ProductCurrency>{};
    for (final p in widget.products) {
      set.addAll(p.acceptedCurrencies);
    }
    return set;
  }

  double get _maxCatalogPrice {
    double max = 0;
    for (final p in widget.products) {
      if (p.price > max) max = p.price;
    }
    return max;
  }

  bool get _hasActiveFilters =>
      _nameQuery.trim().isNotEmpty ||
      _categoryFilter != null ||
      _conditionFilters.isNotEmpty ||
      _currencyFilters.isNotEmpty ||
      _sortOrder != ProductSortOrder.none ||
      _priceRange != null;

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    final query = _nameQuery.trim().toLowerCase();
    final filtered = products.where((p) {
      if (query.isNotEmpty) {
        final matchesName = p.name.toLowerCase().contains(query);
        final matchesVersion = p.version.toLowerCase().contains(query);
        if (!matchesName && !matchesVersion) return false;
      }
      if (_categoryFilter != null && p.category != _categoryFilter) {
        return false;
      }
      if (_conditionFilters.isNotEmpty &&
          (p.condition == null || !_conditionFilters.contains(p.condition))) {
        return false;
      }
      if (_currencyFilters.isNotEmpty &&
          !p.acceptedCurrencies.any(_currencyFilters.contains)) {
        return false;
      }
      if (_priceRange != null) {
        if (p.price < _priceRange!.start || p.price > _priceRange!.end) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_sortOrder) {
      case ProductSortOrder.priceAsc:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOrder.priceDesc:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOrder.none:
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    final hasProducts = products.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 480;

    final availableCategories = _availableCategories;
    final effectiveCategory =
        (_categoryFilter != null &&
            availableCategories.contains(_categoryFilter))
        ? _categoryFilter
        : null;
    final maxPrice = _maxCatalogPrice;
    final filteredProducts = hasProducts ? _applyFilters(products) : products;

    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.foregroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Catalogo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              widget.store.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          if (hasProducts)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isCompact
                  ? IconButton(
                      tooltip: 'Agregar producto',
                      onPressed: () => _openCreate(context),
                      icon: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _openCreate(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Agregar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
            ),
        ],
      ),
      body: hasProducts
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProductFilters(
                        nameController: _searchController,
                        onNameChanged: (value) =>
                            setState(() => _nameQuery = value),
                        availableCategories: availableCategories,
                        selectedCategory: effectiveCategory,
                        onCategoryChanged: (value) =>
                            setState(() => _categoryFilter = value),
                        availableConditions: _availableConditions,
                        selectedConditions: _conditionFilters,
                        onConditionToggle: (condition) {
                          setState(() {
                            if (_conditionFilters.contains(condition)) {
                              _conditionFilters.remove(condition);
                            } else {
                              _conditionFilters.add(condition);
                            }
                          });
                        },
                        availableCurrencies: _availableCurrencies,
                        selectedCurrencies: _currencyFilters,
                        onCurrencyToggle: (currency) {
                          setState(() {
                            if (_currencyFilters.contains(currency)) {
                              _currencyFilters.remove(currency);
                            } else {
                              _currencyFilters.add(currency);
                            }
                          });
                        },
                        sortOrder: _sortOrder,
                        onSortChanged: (value) =>
                            setState(() => _sortOrder = value),
                        maxPrice: maxPrice,
                        priceRange: _priceRange,
                        onPriceRangeChanged: (range) =>
                            setState(() => _priceRange = range),
                        onPriceRangeReset: () =>
                            setState(() => _priceRange = null),
                        hasActiveFilters: _hasActiveFilters,
                        onClearFilters: _resetFilters,
                        totalCount: products.length,
                        filteredCount: filteredProducts.length,
                      ),
                      const SizedBox(height: 12),
                      if (filteredProducts.isEmpty)
                        _NoMatchesState(onClearFilters: _resetFilters)
                      else
                        _ProductsGrid(
                          products: filteredProducts,
                          onEdit: (p) => _openEdit(context, p),
                          onDelete: (p) => _confirmDelete(context, p),
                        ),
                    ],
                  ),
                ),
              ),
            )
          : _ProductsEmptyState(
              storeName: widget.store.name,
              onAdd: () => _openCreate(context),
            ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final List<ProductModel> products;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;

  const _ProductsGrid({
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 720 ? 2 : 1;
        final cardWidth =
            (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final product in products)
              SizedBox(
                width: cardWidth,
                child: ProductCard(
                  key: ValueKey(product.id),
                  product: product,
                  onEdit: () => onEdit(product),
                  onDelete: () => onDelete(product),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProductFilters extends StatelessWidget {
  final TextEditingController nameController;
  final ValueChanged<String> onNameChanged;
  final List<String> availableCategories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final Set<ProductCondition> availableConditions;
  final Set<ProductCondition> selectedConditions;
  final ValueChanged<ProductCondition> onConditionToggle;
  final Set<ProductCurrency> availableCurrencies;
  final Set<ProductCurrency> selectedCurrencies;
  final ValueChanged<ProductCurrency> onCurrencyToggle;
  final ProductSortOrder sortOrder;
  final ValueChanged<ProductSortOrder> onSortChanged;
  final double maxPrice;
  final RangeValues? priceRange;
  final ValueChanged<RangeValues> onPriceRangeChanged;
  final VoidCallback onPriceRangeReset;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;
  final int totalCount;
  final int filteredCount;

  const _ProductFilters({
    required this.nameController,
    required this.onNameChanged,
    required this.availableCategories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.availableConditions,
    required this.selectedConditions,
    required this.onConditionToggle,
    required this.availableCurrencies,
    required this.selectedCurrencies,
    required this.onCurrencyToggle,
    required this.sortOrder,
    required this.onSortChanged,
    required this.maxPrice,
    required this.priceRange,
    required this.onPriceRangeChanged,
    required this.onPriceRangeReset,
    required this.hasActiveFilters,
    required this.onClearFilters,
    required this.totalCount,
    required this.filteredCount,
  });

  String _formatPrice(double price) {
    if (price == price.truncateToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2);
  }

  Widget _buildSearchField() {
    return TextField(
      controller: nameController,
      onChanged: onNameChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por nombre o modelo',
        hintStyle: TextStyle(color: AppTheme.hintColor),
        prefixIcon: Icon(Icons.search, size: 18, color: AppTheme.textMuted),
        suffixIcon: nameController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar',
                icon: Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                onPressed: () {
                  nameController.clear();
                  onNameChanged('');
                },
              ),
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
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          dropdownColor: AppTheme.foregroundColor,
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          hint: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hint,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return _buildDropdown<String?>(
      value: selectedCategory,
      hint: 'Todas las categorias',
      icon: Icons.category_outlined,
      items: <DropdownMenuItem<String?>>[
        DropdownMenuItem<String?>(
          value: null,
          child: Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Todas las categorias',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        for (final category in availableCategories)
          DropdownMenuItem<String?>(
            value: category,
            child: Text(
              category,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onCategoryChanged,
    );
  }

  Widget _buildSortDropdown() {
    return _buildDropdown<ProductSortOrder>(
      value: sortOrder,
      hint: 'Sin orden',
      icon: Icons.swap_vert,
      items: [
        for (final order in ProductSortOrder.values)
          DropdownMenuItem<ProductSortOrder>(
            value: order,
            child: Row(
              children: [
                Icon(
                  order == ProductSortOrder.priceAsc
                      ? Icons.arrow_upward
                      : order == ProductSortOrder.priceDesc
                      ? Icons.arrow_downward
                      : Icons.swap_vert,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onSortChanged(value);
      },
    );
  }

  Widget _buildChipSection<T>({
    required String title,
    required Iterable<T> available,
    required Set<T> selected,
    required ValueChanged<T> onToggle,
    required String Function(T) label,
  }) {
    if (available.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in available)
              FilterChip(
                label: Text(label(option)),
                selected: selected.contains(option),
                onSelected: (_) => onToggle(option),
                selectedColor: AppTheme.primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: AppTheme.inputFillColor,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected.contains(option)
                      ? Colors.white
                      : AppTheme.textPrimary,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: selected.contains(option)
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceRange(BuildContext context) {
    if (maxPrice <= 0) return const SizedBox.shrink();
    final effectiveRange = priceRange ?? RangeValues(0, maxPrice);
    final start = effectiveRange.start.clamp(0, maxPrice).toDouble();
    final end = effectiveRange.end.clamp(0, maxPrice).toDouble();
    final isCustom = priceRange != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.price_change_outlined,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Rango de precio',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_formatPrice(start)} - ${_formatPrice(end)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (isCustom)
                IconButton(
                  tooltip: 'Restablecer precio',
                  onPressed: onPriceRangeReset,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  icon: Icon(
                    Icons.refresh,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 7,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: RangeSlider(
              values: RangeValues(start, end),
              min: 0,
              max: maxPrice,
              divisions: 20,
              activeColor: AppTheme.primaryColor,
              inactiveColor: AppTheme.dividerColor,
              labels: RangeLabels(_formatPrice(start), _formatPrice(end)),
              onChanged: onPriceRangeChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          final categoryDropdown = _buildCategoryDropdown();
          final sortDropdown = _buildSortDropdown();

          final dropdownsRow = isWide
              ? Row(
                  children: [
                    Expanded(child: categoryDropdown),
                    const SizedBox(width: 10),
                    Expanded(child: sortDropdown),
                  ],
                )
              : Column(
                  children: [
                    categoryDropdown,
                    const SizedBox(height: 10),
                    sortDropdown,
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasActiveFilters
                        ? '$filteredCount de $totalCount'
                        : '$totalCount ${totalCount == 1 ? 'producto' : 'productos'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (hasActiveFilters)
                    TextButton.icon(
                      onPressed: onClearFilters,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text(
                        'Limpiar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _buildSearchField(),
              const SizedBox(height: 10),
              dropdownsRow,
              if (availableConditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildChipSection<ProductCondition>(
                  title: 'ESTADO',
                  available: availableConditions,
                  selected: selectedConditions,
                  onToggle: onConditionToggle,
                  label: (condition) => condition.label,
                ),
              ],
              if (availableCurrencies.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildChipSection<ProductCurrency>(
                  title: 'MONEDAS',
                  available: availableCurrencies,
                  selected: selectedCurrencies,
                  onToggle: onCurrencyToggle,
                  label: (currency) =>
                      '${currency.symbol} ${currency.value}',
                ),
              ],
              if (maxPrice > 0) ...[
                const SizedBox(height: 12),
                _buildPriceRange(context),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NoMatchesState extends StatelessWidget {
  final VoidCallback onClearFilters;

  const _NoMatchesState({required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.foregroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Icon(
              Icons.search_off,
              size: 28,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ningun producto coincide con los filtros',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Probá ajustando la busqueda o limpiando los filtros para ver tus productos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Limpiar filtros'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  final String storeName;
  final VoidCallback onAdd;

  const _ProductsEmptyState({required this.storeName, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.selectedColor,
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 44,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Tu catalogo aun esta vacio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega los productos que vendes en "$storeName" para que tus clientes puedan verlos y comprarlos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    'Agregar mi primer producto',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cuando ya tengas productos, el boton para agregar mas estara siempre arriba a la derecha.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
