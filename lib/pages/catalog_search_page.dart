import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/pages/catalog_search/catalog_search_filters.dart';
import 'package:vibe_trade_v1/pages/catalog_search/catalog_search_helpers.dart';
import 'package:vibe_trade_v1/pages/catalog_search/catalog_search_results.dart';
import 'package:vibe_trade_v1/services/catalog_search_service.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Pantalla de filtros para descubrir ofertas, tiendas, productos, servicios
/// y hojas de ruta. Equivalente al `CatalogSearchPage` del demo en React.
///
/// Se abre desde la AppBar de Home (`HomeOffersAppBar`) tocando la caja "Buscar".
class CatalogSearchPage extends StatefulWidget {
  const CatalogSearchPage({super.key});

  @override
  State<CatalogSearchPage> createState() => _CatalogSearchPageState();
}

class _CatalogSearchPageState extends State<CatalogSearchPage> {
  static const int _pageSize = 20;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _kmCtrl = TextEditingController();
  final TextEditingController _trustCtrl = TextEditingController();

  List<String> _availableCategories = const [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  List<String> _selectedCategories = const [];
  Set<CatalogSearchKind> _selectedKinds = Set<CatalogSearchKind>.from(
    CatalogSearchKind.values,
  );

  List<CatalogSearchItem> _results = const [];
  bool _hasMore = false;
  int _pageIndex = 0;

  SearchStatus _status = SearchStatus.idle;
  String? _statusError;

  List<String> _suggestions = const [];
  bool _suggestionsVisible = false;
  Timer? _autocompleteDebounce;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _nameCtrl.dispose();
    _kmCtrl.dispose();
    _trustCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = null;
    });
    try {
      final cats = await MarketService.getCatalogCategories();
      if (!mounted) return;
      setState(() {
        _availableCategories = cats;
        _categoriesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _categoriesError = error.toString().replaceFirst('Exception: ', '');
        _categoriesLoading = false;
      });
    }
  }

  void _onNameChanged(String value) {
    _autocompleteDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _suggestions = const [];
        _suggestionsVisible = false;
      });
      return;
    }
    _autocompleteDebounce = Timer(const Duration(milliseconds: 220), () async {
      try {
        final next = await CatalogSearchService.autocomplete(
          trimmed,
          kinds: _selectedKinds.toList(),
          categories: _selectedCategories,
          limit: 10,
        );
        if (!mounted) return;
        setState(() {
          _suggestions = next;
          _suggestionsVisible = next.isNotEmpty;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = const [];
          _suggestionsVisible = false;
        });
      }
    });
  }

  Future<void> _runSearch(int nextPageIndex) async {
    setState(() {
      _status = SearchStatus.loading;
      _statusError = null;
      _suggestionsVisible = false;
    });
    try {
      final kmText = _kmCtrl.text.trim();
      final trustText = _trustCtrl.text.trim();
      final kmNum = double.tryParse(kmText);
      final trustNum = double.tryParse(trustText);
      final wantsRadius = kmNum != null && kmNum > 0;

      final page = await CatalogSearchService.search(
        name: _nameCtrl.text.trim(),
        categories: _selectedCategories,
        kinds: _selectedKinds.toList(),
        trustMin: trustNum,
        km: wantsRadius ? kmNum : null,
        limit: _pageSize,
        offset: nextPageIndex * _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _results = page.items;
        _hasMore = page.hasMore;
        _pageIndex = nextPageIndex;
        _status = SearchStatus.ready;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusError = error.toString().replaceFirst('Exception: ', '');
        _status = SearchStatus.error;
      });
    }
  }

  void _toggleKind(CatalogSearchKind kind, bool selected) {
    setState(() {
      final next = Set<CatalogSearchKind>.from(_selectedKinds);
      if (selected) {
        next.add(kind);
      } else {
        next.remove(kind);
      }
      _selectedKinds = next.isEmpty
          ? Set<CatalogSearchKind>.from(CatalogSearchKind.values)
          : next;
    });
  }

  void _addCategory(String? cat) {
    if (cat == null || cat.trim().isEmpty) return;
    if (_selectedCategories.contains(cat)) return;
    setState(() {
      _selectedCategories = [..._selectedCategories, cat];
    });
  }

  void _removeCategory(String cat) {
    setState(() {
      _selectedCategories = _selectedCategories
          .where((c) => c != cat)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.appBgColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Buscar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tiendas, productos, servicios y hojas de ruta.',
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _buildFiltersCard(),
            const SizedBox(height: 16),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: 'Buscar',
            child: NameAutocompleteField(
              controller: _nameCtrl,
              suggestions: _suggestionsVisible ? _suggestions : const [],
              onChanged: _onNameChanged,
              onSelectSuggestion: (s) {
                _nameCtrl.text = s;
                setState(() {
                  _suggestionsVisible = false;
                });
              },
              onSubmitted: () => _runSearch(0),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Categorias',
            child: CategoryPicker(
              loading: _categoriesLoading,
              error: _categoriesError,
              available: _availableCategories,
              selected: _selectedCategories,
              onAdd: _addCategory,
              onRemove: _removeCategory,
              onRetry: _loadCategories,
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Tipo',
            child: KindFilter(selected: _selectedKinds, onToggle: _toggleKind),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Radio (km)',
                  child: NumberField(controller: _kmCtrl, hint: 'Ej: 10'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LabeledField(
                  label: 'Confianza minima',
                  child: NumberField(controller: _trustCtrl, hint: 'Ej: 80'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _status == SearchStatus.loading
                  ? null
                  : () => _runSearch(0),
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                _status == SearchStatus.loading ? 'Buscando...' : 'Buscar',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.primaryColor.withValues(
                  alpha: 0.6,
                ),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    switch (_status) {
      case SearchStatus.idle:
        return HelperText(
          icon: Icons.search,
          text: 'Elige filtros y pulsa la lupa para ver resultados.',
        );
      case SearchStatus.loading:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        );
      case SearchStatus.error:
        return HelperText(
          icon: Icons.error_outline,
          text: _statusError ?? 'No se pudo buscar.',
          color: AppTheme.errorColor,
        );
      case SearchStatus.ready:
        if (_results.isEmpty) {
          return const HelperText(
            icon: Icons.search_off,
            text: 'Sin resultados para esta busqueda.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _results.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              ResultCard(item: _results[i]),
            ],
            const SizedBox(height: 14),
            PaginationRow(
              hasPrev: _pageIndex > 0,
              hasNext: _hasMore,
              onPrev: () => _runSearch(_pageIndex - 1),
              onNext: () => _runSearch(_pageIndex + 1),
            ),
          ],
        );
    }
  }
}
