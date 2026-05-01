import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/store_model.dart';
import 'package:vibe_trade_v1/pages/store_detail_page.dart';
import 'package:vibe_trade_v1/services/store_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/new_store_modal.dart';
import 'package:vibe_trade_v1/widgets/storeConfiguration/store_card.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _nameQuery = '';
  String? _categoryFilter;
  double _minTrustFilter = 0;

  @override
  void initState() {
    super.initState();
    StoreService.hydrate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _openCreateStore() async {
    await showNewStoreModal(context);
  }

  Future<void> _openEditStore(StoreModel store) async {
    await showNewStoreModal(context, initialStore: store);
  }

  void _openStoreDetail(StoreModel store) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoreDetailPage(storeId: store.id)),
    );
  }

  Future<void> _confirmDelete(StoreModel store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.foregroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar tienda'),
        content: Text(
          'Seguro que quieres eliminar la tienda "${store.name}"? Esta accion no se puede deshacer.',
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
      await StoreService.deleteStore(store.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tienda "${store.name}" eliminada')),
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

  void _resetFilters() {
    _nameController.clear();
    setState(() {
      _nameQuery = '';
      _categoryFilter = null;
      _minTrustFilter = 0;
    });
  }

  List<String> _availableCategoriesFor(List<StoreModel> stores) {
    final set = <String>{};
    for (final store in stores) {
      set.addAll(store.categories);
    }
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  List<StoreModel> _filterStores(
    List<StoreModel> stores,
    String? effectiveCategory,
  ) {
    final query = _nameQuery.trim().toLowerCase();
    final minTrust = _minTrustFilter.round();
    return stores.where((store) {
      if (query.isNotEmpty &&
          !store.name.toLowerCase().contains(query)) {
        return false;
      }
      if (effectiveCategory != null &&
          !store.categories.contains(effectiveCategory)) {
        return false;
      }
      if (store.trustScore < minTrust) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  bool get _hasActiveFilters =>
      _nameQuery.trim().isNotEmpty ||
      _categoryFilter != null ||
      _minTrustFilter > 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StoreModel>>(
      valueListenable: StoreService.storesNotifier,
      builder: (context, stores, _) {
        final availableCategories = _availableCategoriesFor(stores);
        final effectiveCategory =
            (_categoryFilter != null &&
                availableCategories.contains(_categoryFilter))
            ? _categoryFilter
            : null;
        final filteredStores = _filterStores(stores, effectiveCategory);

        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.foregroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppTheme.isDark ? 0.4 : 0.06,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(count: stores.length),
                const SizedBox(height: 16),
                if (stores.isEmpty)
                  _EmptyState(onAdd: _openCreateStore)
                else ...[
                  _StoreFilters(
                    nameController: _nameController,
                    onNameChanged: (value) =>
                        setState(() => _nameQuery = value),
                    selectedCategory: effectiveCategory,
                    availableCategories: availableCategories,
                    onCategoryChanged: (value) =>
                        setState(() => _categoryFilter = value),
                    minTrust: _minTrustFilter,
                    onMinTrustChanged: (value) =>
                        setState(() => _minTrustFilter = value),
                    hasActiveFilters: _hasActiveFilters,
                    onClearFilters: _resetFilters,
                  ),
                  const SizedBox(height: 12),
                  if (filteredStores.isEmpty)
                    _NoMatchesState(onClearFilters: _resetFilters)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 12.0;
                        final isWide = constraints.maxWidth >= 720;
                        final columns = isWide ? 2 : 1;
                        final cardWidth = columns == 1
                            ? constraints.maxWidth
                            : (constraints.maxWidth -
                                      spacing * (columns - 1)) /
                                  columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final store in filteredStores)
                              SizedBox(
                                width: cardWidth,
                                child: StoreCard(
                                  key: ValueKey(store.id),
                                  store: store,
                                  onOpen: () => _openStoreDetail(store),
                                  onEdit: () => _openEditStore(store),
                                  onDelete: () => _confirmDelete(store),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openCreateStore,
                    icon: const Icon(Icons.add_business_outlined, size: 18),
                    label: const Text(
                      'Agregar tienda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.foregroundColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int count;

  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 5),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Mis tiendas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.selectedColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreFilters extends StatelessWidget {
  final TextEditingController nameController;
  final ValueChanged<String> onNameChanged;
  final String? selectedCategory;
  final List<String> availableCategories;
  final ValueChanged<String?> onCategoryChanged;
  final double minTrust;
  final ValueChanged<double> onMinTrustChanged;
  final bool hasActiveFilters;
  final VoidCallback onClearFilters;

  const _StoreFilters({
    required this.nameController,
    required this.onNameChanged,
    required this.selectedCategory,
    required this.availableCategories,
    required this.onCategoryChanged,
    required this.minTrust,
    required this.onMinTrustChanged,
    required this.hasActiveFilters,
    required this.onClearFilters,
  });

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      onChanged: onNameChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Buscar por nombre',
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
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          hint: Row(
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
                  color: AppTheme.textMuted,
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

  Widget _buildTrustSlider(BuildContext context) {
    final value = minTrust.round();
    final color = value < 30
        ? AppTheme.errorColor
        : value <= 60
        ? AppTheme.warningColor
        : AppTheme.successColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Confianza minima',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '$value%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: minTrust.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: color,
              inactiveColor: AppTheme.dividerColor,
              label: '$value%',
              onChanged: onMinTrustChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final fields = <Widget>[
          _buildNameField(),
          _buildCategoryDropdown(),
          _buildTrustSlider(context),
        ];

        Widget filtersRow;
        if (isWide) {
          filtersRow = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: fields[0]),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: fields[1]),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: fields[2]),
            ],
          );
        } else {
          filtersRow = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              fields[0],
              const SizedBox(height: 10),
              fields[1],
              const SizedBox(height: 10),
              fields[2],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
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
            const SizedBox(height: 8),
            filtersRow,
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            'No encontramos tiendas con esos filtros',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Probablemente ninguna de tus tiendas coincide con esa busqueda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppTheme.selectedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.foregroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 32,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aun no tienes tiendas agregadas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera tienda para comenzar a gestionarlas desde aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
