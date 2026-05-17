import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/services/catalog_search_service.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

/// Campo de entrada con etiqueta
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const LabeledField({required this.label, required this.child});

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

/// Campo de autocompletado para buscar por nombre
class NameAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSelectSuggestion;
  final VoidCallback onSubmitted;

  const NameAutocompleteField({
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

/// Selector de categorías con dropdown
class CategoryPicker extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<String> available;
  final List<String> selected;
  final ValueChanged<String?> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onRetry;

  const CategoryPicker({
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

    final remaining = available
        .where((cat) => !selected.contains(cat))
        .toList(growable: false);

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
                    ? (selected.isEmpty
                          ? 'No hay categorias'
                          : 'Sin mas categorias')
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

/// Filtro por tipo de búsqueda (ofertas, tiendas, etc)
class KindFilter extends StatelessWidget {
  final Set<CatalogSearchKind> selected;
  final void Function(CatalogSearchKind kind, bool selected) onToggle;

  const KindFilter({required this.selected, required this.onToggle});

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

/// Campo de entrada para números (radio, confianza mínima)
class NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const NumberField({required this.controller, required this.hint});

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
