import 'package:flutter/material.dart';
import 'package:vibe_trade_v1/theme/app_theme.dart';

class StoreCategorySelector extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<String> availableCategories;
  final List<String> selectedCategories;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String> onCategoryRemoved;
  final VoidCallback onRetry;

  const StoreCategorySelector({
    super.key,
    required this.loading,
    required this.error,
    required this.availableCategories,
    required this.selectedCategories,
    required this.onCategorySelected,
    required this.onCategoryRemoved,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _CategoryLoading();
    if (error != null) return _CategoryError(error: error!, onRetry: onRetry);

    final remaining = availableCategories
        .where((cat) => !selectedCategories.contains(cat))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryDropdown(
          remainingCategories: remaining,
          selectedCount: selectedCategories.length,
          onChanged: onCategorySelected,
        ),
        if (selectedCategories.isNotEmpty)
          _SelectedCategoryChips(
            selectedCategories: selectedCategories,
            onDeleted: onCategoryRemoved,
          ),
      ],
    );
  }
}

class _CategoryLoading extends StatelessWidget {
  const _CategoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _CategoryError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _CategoryError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            error,
            style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<String> remainingCategories;
  final int selectedCount;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.remainingCategories,
    required this.selectedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.inputFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: ValueKey<int>(selectedCount),
          value: null,
          dropdownColor: AppTheme.foregroundColor,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          hint: Text(_hintText, style: TextStyle(color: AppTheme.hintColor)),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
          items: _items,
          onChanged: remainingCategories.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  String get _hintText {
    return remainingCategories.isEmpty
        ? 'No hay mas categorias'
        : 'Selecciona una categoria';
  }

  List<DropdownMenuItem<String>> get _items {
    return remainingCategories
        .map((cat) => DropdownMenuItem<String>(
              value: cat,
              child: Text(
                cat,
                style: TextStyle(color: AppTheme.textPrimary),
              ),
            ))
        .toList();
  }
}

class _SelectedCategoryChips extends StatelessWidget {
  final List<String> selectedCategories;
  final ValueChanged<String> onDeleted;

  const _SelectedCategoryChips({
    required this.selectedCategories,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: selectedCategories
            .map((cat) => _CategoryChip(category: cat, onDeleted: onDeleted))
            .toList(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  final ValueChanged<String> onDeleted;

  const _CategoryChip({required this.category, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        category,
        style: TextStyle(color: AppTheme.primaryColor),
      ),
      backgroundColor: AppTheme.selectedColor,
      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      deleteIcon: Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
      onDeleted: () => onDeleted(category),
    );
  }
}
