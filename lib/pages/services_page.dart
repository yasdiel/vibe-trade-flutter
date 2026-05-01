import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/product_model.dart';
import 'package:vibe_trade_v1/models/service_model.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/services/service_service.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/serviceConfiguration/new_service_modal.dart';
import 'package:vibe_trade_v1/widgets/serviceConfiguration/service_card.dart';

enum ServiceTrait { withWarranty, withRisks, withDependencies }

extension ServiceTraitLabel on ServiceTrait {
  String get label {
    switch (this) {
      case ServiceTrait.withWarranty:
        return 'Con garantia';
      case ServiceTrait.withRisks:
        return 'Con riesgos';
      case ServiceTrait.withDependencies:
        return 'Con dependencias';
    }
  }
}

class ServicesPage extends StatelessWidget {
  final String storeId;

  const ServicesPage({super.key, required this.storeId});

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
              title: const Text('Servicios'),
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

        return ValueListenableBuilder<List<ServiceModel>>(
          valueListenable: ServiceService.servicesNotifier,
          builder: (context, allServices, _) {
            final services = allServices
                .where((s) => s.storeId == store.id)
                .toList(growable: false);
            return _ServicesScaffold(store: store, services: services);
          },
        );
      },
    );
  }
}

class _ServicesScaffold extends StatefulWidget {
  final StoreModel store;
  final List<ServiceModel> services;

  const _ServicesScaffold({required this.store, required this.services});

  @override
  State<_ServicesScaffold> createState() => _ServicesScaffoldState();
}

class _ServicesScaffoldState extends State<_ServicesScaffold> {
  final TextEditingController _searchController = TextEditingController();
  String _nameQuery = '';
  String? _categoryFilter;
  final Set<ProductCurrency> _currencyFilters = <ProductCurrency>{};
  final Set<ServiceTrait> _traitFilters = <ServiceTrait>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate(BuildContext context) async {
    await showServiceModal(context, storeId: widget.store.id);
  }

  Future<void> _openEdit(BuildContext context, ServiceModel service) async {
    await showServiceModal(
      context,
      storeId: widget.store.id,
      initialService: service,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ServiceModel service,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar servicio'),
        content: Text(
          'Seguro que quieres eliminar "${service.serviceType}"? Esta accion no se puede deshacer.',
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
      await ServiceService.deleteService(service.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Servicio "${service.serviceType}" eliminado')),
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
      _currencyFilters.clear();
      _traitFilters.clear();
    });
  }

  List<String> get _availableCategories {
    final set = <String>{};
    for (final s in widget.services) {
      if (s.category.isNotEmpty) set.add(s.category);
    }
    final list = set.toList()..sort();
    return list;
  }

  Set<ProductCurrency> get _availableCurrencies {
    final set = <ProductCurrency>{};
    for (final s in widget.services) {
      set.addAll(s.acceptedCurrencies);
    }
    return set;
  }

  bool get _hasActiveFilters =>
      _nameQuery.trim().isNotEmpty ||
      _categoryFilter != null ||
      _currencyFilters.isNotEmpty ||
      _traitFilters.isNotEmpty;

  bool _matchesTrait(ServiceModel service, ServiceTrait trait) {
    switch (trait) {
      case ServiceTrait.withWarranty:
        return service.hasWarranty;
      case ServiceTrait.withRisks:
        return service.hasRisks;
      case ServiceTrait.withDependencies:
        return service.hasDependencies;
    }
  }

  List<ServiceModel> _applyFilters(List<ServiceModel> services) {
    final query = _nameQuery.trim().toLowerCase();
    return services.where((s) {
      if (query.isNotEmpty) {
        final matchesType = s.serviceType.toLowerCase().contains(query);
        final matchesDescription =
            s.description.toLowerCase().contains(query);
        if (!matchesType && !matchesDescription) return false;
      }
      if (_categoryFilter != null && s.category != _categoryFilter) {
        return false;
      }
      if (_currencyFilters.isNotEmpty &&
          !s.acceptedCurrencies.any(_currencyFilters.contains)) {
        return false;
      }
      if (_traitFilters.isNotEmpty &&
          !_traitFilters.every((trait) => _matchesTrait(s, trait))) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    final hasServices = services.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 480;

    final availableCategories = _availableCategories;
    final effectiveCategory =
        (_categoryFilter != null &&
            availableCategories.contains(_categoryFilter))
        ? _categoryFilter
        : null;
    final filteredServices = hasServices ? _applyFilters(services) : services;

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
              'Servicios',
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
          if (hasServices)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isCompact
                  ? IconButton(
                      tooltip: 'Agregar servicio',
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
      body: hasServices
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ServiceFilters(
                        nameController: _searchController,
                        onNameChanged: (value) =>
                            setState(() => _nameQuery = value),
                        availableCategories: availableCategories,
                        selectedCategory: effectiveCategory,
                        onCategoryChanged: (value) =>
                            setState(() => _categoryFilter = value),
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
                        selectedTraits: _traitFilters,
                        onTraitToggle: (trait) {
                          setState(() {
                            if (_traitFilters.contains(trait)) {
                              _traitFilters.remove(trait);
                            } else {
                              _traitFilters.add(trait);
                            }
                          });
                        },
                        hasActiveFilters: _hasActiveFilters,
                        onClearFilters: _resetFilters,
                        totalCount: services.length,
                        filteredCount: filteredServices.length,
                      ),
                      const SizedBox(height: 12),
                      if (filteredServices.isEmpty)
                        _NoMatchesState(onClearFilters: _resetFilters)
                      else
                        _ServicesGrid(
                          services: filteredServices,
                          onEdit: (s) => _openEdit(context, s),
                          onDelete: (s) => _confirmDelete(context, s),
                        ),
                    ],
                  ),
                ),
              ),
            )
          : _ServicesEmptyState(
              storeName: widget.store.name,
              onAdd: () => _openCreate(context),
            ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final List<ServiceModel> services;
  final ValueChanged<ServiceModel> onEdit;
  final ValueChanged<ServiceModel> onDelete;

  const _ServicesGrid({
    required this.services,
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
        final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final service in services)
              SizedBox(
                width: cardWidth,
                child: ServiceCard(
                  key: ValueKey(service.id),
                  service: service,
                  onEdit: () => onEdit(service),
                  onDelete: () => onDelete(service),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ServiceFilters extends StatelessWidget {
  final TextEditingController nameController;
  final ValueChanged<String> onNameChanged;
  final List<String> availableCategories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final Set<ProductCurrency> availableCurrencies;
  final Set<ProductCurrency> selectedCurrencies;
  final ValueChanged<ProductCurrency> onCurrencyToggle;
  final Set<ServiceTrait> selectedTraits;
  final ValueChanged<ServiceTrait> onTraitToggle;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;
  final int totalCount;
  final int filteredCount;

  const _ServiceFilters({
    required this.nameController,
    required this.onNameChanged,
    required this.availableCategories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.availableCurrencies,
    required this.selectedCurrencies,
    required this.onCurrencyToggle,
    required this.selectedTraits,
    required this.onTraitToggle,
    required this.hasActiveFilters,
    required this.onClearFilters,
    required this.totalCount,
    required this.filteredCount,
  });

  Widget _buildSearchField() {
    return TextField(
      controller: nameController,
      onChanged: onNameChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por tipo de servicio o descripcion',
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

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: selectedCategory,
          dropdownColor: AppTheme.foregroundColor,
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          hint: Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Todas las categorias',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onCategoryChanged,
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
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
                    : '$totalCount ${totalCount == 1 ? 'servicio' : 'servicios'}',
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
          _buildCategoryDropdown(),
          if (availableCurrencies.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildChipSection<ProductCurrency>(
              title: 'MONEDAS',
              available: availableCurrencies,
              selected: selectedCurrencies,
              onToggle: onCurrencyToggle,
              label: (currency) => '${currency.symbol} ${currency.value}',
            ),
          ],
          const SizedBox(height: 12),
          _buildChipSection<ServiceTrait>(
            title: 'CARACTERISTICAS',
            available: ServiceTrait.values,
            selected: selectedTraits,
            onToggle: onTraitToggle,
            label: (trait) => trait.label,
          ),
        ],
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
            'Ningun servicio coincide con los filtros',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Probá ajustando la busqueda o limpiando los filtros para ver tus servicios.',
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

class _ServicesEmptyState extends StatelessWidget {
  final String storeName;
  final VoidCallback onAdd;

  const _ServicesEmptyState({required this.storeName, required this.onAdd});

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
                  Icons.handyman_outlined,
                  size: 44,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Aun no ofreces servicios',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega los servicios que prestas desde "$storeName" para que tus clientes puedan contratarlos.',
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
                    'Agregar mi primer servicio',
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
                'Cuando ya tengas servicios, el boton para agregar mas estara siempre arriba a la derecha.',
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
