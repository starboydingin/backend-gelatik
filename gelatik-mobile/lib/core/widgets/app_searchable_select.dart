import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A mobile-native select for long server-provided lists such as OPD and
/// consultation topics. Native dropdown menus truncate long labels and do not
/// offer filtering, so the list is opened in a searchable bottom sheet.
class SearchableSelectOption<T> {
  final T value;
  final String label;
  final String? detail;

  const SearchableSelectOption({
    required this.value,
    required this.label,
    this.detail,
  });
}

class AppSearchableSelect<T> extends StatelessWidget {
  final String labelText;
  final String hintText;
  final String searchHint;
  final T? value;
  final List<SearchableSelectOption<T>> options;
  final ValueChanged<T>? onChanged;
  final String? errorText;
  final Widget? prefixIcon;
  final bool enabled;

  const AppSearchableSelect({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.searchHint,
    required this.options,
    required this.onChanged,
    this.value,
    this.errorText,
    this.prefixIcon,
    this.enabled = true,
  });

  SearchableSelectOption<T>? get _selected {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _SearchableSelectSheet<T>(
        title: labelText,
        searchHint: searchHint,
        options: options,
        selectedValue: value,
      ),
    );
    if (selected != null) onChanged?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selected;
    final border = AppColors.cardStroke(context);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: border, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            labelText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: errorText == null
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.error,
            ),
          ),
        ),
        Semantics(
          button: true,
          label: labelText,
          value: selected?.label ?? hintText,
          child: InkWell(
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              isEmpty: false,
              decoration: InputDecoration(
                errorText: errorText,
                prefixIcon: prefixIcon,
                suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: fieldBorder,
                enabledBorder: fieldBorder,
                focusedBorder: fieldBorder.copyWith(
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: fieldBorder.copyWith(
                  borderSide: BorderSide(
                    color: theme.colorScheme.error,
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(
                selected?.label ?? hintText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected == null
                      ? theme.hintColor
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchableSelectSheet<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<SearchableSelectOption<T>> options;
  final T? selectedValue;

  const _SearchableSelectSheet({
    required this.title,
    required this.searchHint,
    required this.options,
    required this.selectedValue,
  });

  @override
  State<_SearchableSelectSheet<T>> createState() =>
      _SearchableSelectSheetState<T>();
}

class _SearchableSelectSheetState<T> extends State<_SearchableSelectSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final normalized = _query.trim().toLowerCase();
    final filtered = widget.options
        .where((option) {
          return normalized.isEmpty ||
              option.label.toLowerCase().contains(normalized) ||
              (option.detail?.toLowerCase().contains(normalized) ?? false);
        })
        .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: const Key('searchable-select-search-field'),
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Tidak ada pilihan yang cocok.'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final isSelected = option.value == widget.selectedValue;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          title: Text(option.label),
                          subtitle: option.detail == null
                              ? null
                              : Text(option.detail!),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryTeal(context),
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
