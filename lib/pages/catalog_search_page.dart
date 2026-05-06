import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/models/store_badge_model.dart';
import 'package:vibe_trade_v1/pages/public_offer_page.dart';
import 'package:vibe_trade_v1/pages/public_store_page.dart';
import 'package:vibe_trade_v1/services/catalog_search_service.dart';
import 'package:vibe_trade_v1/services/market_service.dart';
import 'package:vibe_trade_v1/services/media_service.dart';
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
  Set<CatalogSearchKind> _selectedKinds =
      Set<CatalogSearchKind>.from(CatalogSearchKind.values);

  List<CatalogSearchItem> _results = const [];
  bool _hasMore = false;
  int _pageIndex = 0;

  _SearchStatus _status = _SearchStatus.idle;
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
      _status = _SearchStatus.loading;
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
        _status = _SearchStatus.ready;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusError = error.toString().replaceFirst('Exception: ', '');
        _status = _SearchStatus.error;
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
      _selectedKinds =
          next.isEmpty ? Set<CatalogSearchKind>.from(CatalogSearchKind.values) : next;
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
      _selectedCategories =
          _selectedCategories.where((c) => c != cat).toList(growable: false);
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
          _LabeledField(
            label: 'Buscar',
            child: _NameAutocompleteField(
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
          _LabeledField(
            label: 'Categorias',
            child: _CategoryPicker(
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
          _LabeledField(
            label: 'Tipo',
            child: _KindFilter(
              selected: _selectedKinds,
              onToggle: _toggleKind,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Radio (km)',
                  child: _NumberField(
                    controller: _kmCtrl,
                    hint: 'Ej: 10',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Confianza minima',
                  child: _NumberField(
                    controller: _trustCtrl,
                    hint: 'Ej: 80',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed:
                  _status == _SearchStatus.loading ? null : () => _runSearch(0),
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                _status == _SearchStatus.loading ? 'Buscando...' : 'Buscar',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppTheme.primaryColor.withValues(alpha: 0.6),
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
      case _SearchStatus.idle:
        return _HelperText(
          icon: Icons.search,
          text:
              'Elige filtros y pulsa la lupa para ver resultados.',
        );
      case _SearchStatus.loading:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        );
      case _SearchStatus.error:
        return _HelperText(
          icon: Icons.error_outline,
          text: _statusError ?? 'No se pudo buscar.',
          color: AppTheme.errorColor,
        );
      case _SearchStatus.ready:
        if (_results.isEmpty) {
          return const _HelperText(
            icon: Icons.search_off,
            text: 'Sin resultados para esta busqueda.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < _results.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _ResultCard(item: _results[i]),
            ],
            const SizedBox(height: 14),
            _PaginationRow(
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

enum _SearchStatus { idle, loading, ready, error }

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _NameAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSelectSuggestion;
  final VoidCallback onSubmitted;

  const _NameAutocompleteField({
    required this.controller,
    required this.suggestions,
    required this.onChanged,
    required this.onSelectSuggestion,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSubmitted(),
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nombre, producto, servicio, ruta...',
            hintStyle: TextStyle(color: AppTheme.hintColor),
            filled: true,
            fillColor: AppTheme.inputFillColor,
            prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: AppTheme.foregroundColor,
              border: Border.all(color: AppTheme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final s in suggestions)
                  InkWell(
                    onTap: () => onSelectSuggestion(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<String> available;
  final List<String> selected;
  final ValueChanged<String?> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onRetry;

  const _CategoryPicker({
    required this.loading,
    required this.error,
    required this.available,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }
    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              error!,
              style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      );
    }

    final remaining =
        available.where((cat) => !selected.contains(cat)).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.inputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: ValueKey<int>(selected.length),
              value: null,
              isExpanded: true,
              dropdownColor: AppTheme.foregroundColor,
              icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              hint: Text(
                remaining.isEmpty
                    ? (selected.isEmpty ? 'No hay categorias' : 'Sin mas categorias')
                    : (selected.isEmpty ? 'Todas' : 'Anadir categoria'),
                style: TextStyle(color: AppTheme.hintColor),
              ),
              items: remaining
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(
                        c,
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: remaining.isEmpty ? null : onAdd,
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in selected)
                Chip(
                  label: Text(
                    c,
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                  backgroundColor: AppTheme.selectedColor,
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  onDeleted: () => onRemove(c),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _KindFilter extends StatelessWidget {
  final Set<CatalogSearchKind> selected;
  final void Function(CatalogSearchKind kind, bool selected) onToggle;

  const _KindFilter({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final k in CatalogSearchKind.values)
          FilterChip(
            label: Text(
              k.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected.contains(k)
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
            selected: selected.contains(k),
            backgroundColor: AppTheme.inputFillColor,
            selectedColor: AppTheme.selectedColor,
            checkmarkColor: AppTheme.primaryColor,
            side: BorderSide(
              color: selected.contains(k)
                  ? AppTheme.primaryColor.withValues(alpha: 0.4)
                  : AppTheme.dividerColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            onSelected: (next) => onToggle(k, next),
          ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _NumberField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.hintColor),
        filled: true,
        fillColor: AppTheme.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _HelperText({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: c,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationRow extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PaginationRow({
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: hasPrev ? onPrev : null,
          icon: const Icon(Icons.chevron_left, size: 16),
          label: const Text('Anterior'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: hasNext ? onNext : null,
          icon: const Icon(Icons.chevron_right, size: 16),
          label: const Text('Siguiente'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjetas de resultado
// ---------------------------------------------------------------------------

class _ResultCard extends StatelessWidget {
  final CatalogSearchItem item;

  const _ResultCard({required this.item});

  void _openStore(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicStorePage(
          storeId: item.store.id,
          initialBadge: item.store,
        ),
      ),
    );
  }

  void _openOffer(BuildContext context) {
    final offer = item.offer;
    if (offer == null) {
      _openStore(context);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicOfferPage(
          offerId: offer.id,
          initialStore: item.store,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStore = item.kind == CatalogSearchKind.store || item.offer == null;
    final body = isStore
        ? _StoreResultCard(
            store: item.store,
            publishedProducts: item.publishedProducts,
            publishedServices: item.publishedServices,
            distanceKm: item.distanceKm,
          )
        : _OfferResultCard(
            store: item.store,
            offer: item.offer!,
            distanceKm: item.distanceKm,
          );

    return Material(
      color: AppTheme.foregroundColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => isStore ? _openStore(context) : _openOffer(context),
        child: body,
      ),
    );
  }
}

String _fmtKm(double v) {
  if (v < 1) return '${(v * 1000).round()} m';
  if (v < 10) return '${v.toStringAsFixed(1)} km';
  return '${v.round()} km';
}

class _StoreResultCard extends StatelessWidget {
  final StoreBadgeModel store;
  final int publishedProducts;
  final int publishedServices;
  final double? distanceKm;

  const _StoreResultCard({
    required this.store,
    required this.publishedProducts,
    required this.publishedServices,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarBox(
            url: store.avatarUrl,
            fallbackIcon: Icons.storefront_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name.isEmpty ? 'Tienda' : store.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (store.verified)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          size: 16,
                          color: AppTheme.successColor,
                        ),
                      ),
                  ],
                ),
                if (store.categories.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    store.categories.join(' . '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _MetaChip(
                      icon: Icons.inventory_2_outlined,
                      text: '$publishedProducts',
                    ),
                    _MetaChip(
                      icon: Icons.handyman_outlined,
                      text: '$publishedServices',
                    ),
                    if (distanceKm != null)
                      _MetaChip(
                        icon: Icons.place_outlined,
                        text: _fmtKm(distanceKm!),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _TrustBar(score: store.trustScore),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferResultCard extends StatelessWidget {
  final StoreBadgeModel store;
  final CatalogSearchOffer offer;
  final double? distanceKm;

  const _OfferResultCard({
    required this.store,
    required this.offer,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = offer.photoUrls.isNotEmpty
        ? MediaService.resolveMediaUrl(offer.photoUrls.first)
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarBox(
            url: imageUrl,
            fallbackIcon: offer.kind == CatalogSearchKind.service
                ? Icons.handyman_outlined
                : offer.kind == CatalogSearchKind.emergent
                    ? Icons.alt_route_outlined
                    : Icons.inventory_2_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _KindPill(kind: offer.kind),
                    const SizedBox(width: 6),
                    if (offer.category.isNotEmpty)
                      Flexible(
                        child: Text(
                          offer.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  offer.name.isEmpty ? 'Sin titulo' : offer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (offer.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    offer.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _PriceRow(offer: offer),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name.isEmpty ? 'Tienda' : store.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (distanceKm != null)
                      _MetaChip(
                        icon: Icons.place_outlined,
                        text: _fmtKm(distanceKm!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final CatalogSearchOffer offer;

  const _PriceRow({required this.offer});

  @override
  Widget build(BuildContext context) {
    final price = offer.price.isNotEmpty
        ? offer.price
        : (offer.currency.isNotEmpty ? offer.currency : '-');

    final extras = offer.acceptedCurrencies
        .where((c) => c.isNotEmpty && c != offer.currency)
        .toList(growable: false);

    return Row(
      children: [
        Flexible(
          child: Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
              height: 1.05,
            ),
          ),
        ),
        if (extras.isNotEmpty) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.selectedColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+ ${extras.join(' / ')}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KindPill extends StatelessWidget {
  final CatalogSearchKind kind;

  const _KindPill({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.selectedColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        kind.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TrustBar extends StatelessWidget {
  final int score;

  const _TrustBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final v = score.clamp(0, 100);
    final color = v < 30
        ? AppTheme.errorColor
        : v <= 60
            ? AppTheme.warningColor
            : AppTheme.successColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              'Confianza',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
              ),
            ),
            const Spacer(),
            Text(
              '$v%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: v / 100,
            backgroundColor: AppTheme.surfaceMutedColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _AvatarBox extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;

  const _AvatarBox({required this.url, required this.fallbackIcon});

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: _size,
        height: _size,
        child: (url != null && url!.isNotEmpty)
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppTheme.surfaceMutedColor,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppTheme.surfaceMutedColor,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: 24,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
