import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_text.dart';

class DropdownOption<T> {
  const DropdownOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? subtitle;
  final bool enabled;
}

/// A labelled dropdown. Set [searchable] for long lists (for example the PSGC
/// barangay list, which can contain hundreds of entries); it opens a searchable
/// sheet instead of a scrolling menu.
class DropdownField<T> extends StatelessWidget {
  const DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
    this.hint = 'Select an option',
    this.validator,
    this.enabled = true,
    this.helperText,
    this.searchable = false,
  });

  final String label;
  final T? value;
  final List<DropdownOption<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? helperText;
  final bool searchable;

  @override
  Widget build(BuildContext context) {
    if (searchable) {
      return _SearchableDropdown<T>(
        label: label,
        value: value,
        items: items,
        onChanged: onChanged,
        hint: hint,
        validator: validator,
        enabled: enabled,
        helperText: helperText,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          key: ValueKey<T?>(value),
          initialValue: value,
          isExpanded: true,
          // Flutter fixes menu rows at 48 px by default, which a label plus
          // subtitle (or large system text) overflows. Null sizes each row to
          // its content, still at least 48 px.
          itemHeight: null,
          // The closed field is one line tall: show only the label there.
          // The subtitle is still shown in the open menu.
          selectedItemBuilder: (BuildContext context) => items
              .map((DropdownOption<T> option) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppText(
                      option.label,
                      variant: AppTextVariant.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          hint: AppText(hint, variant: AppTextVariant.body),
          validator: validator,
          onChanged: enabled ? onChanged : null,
          decoration: InputDecoration(
            helperText: helperText,
            enabled: enabled,
          ),
          items: items
              .map((DropdownOption<T> option) => DropdownMenuItem<T>(
                    value: option.value,
                    enabled: option.enabled,
                    child: _OptionLabel(option: option),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppText(
      label,
      variant: AppTextVariant.label,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.option});

  final DropdownOption<dynamic> option;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppText(
          option.label,
          variant: AppTextVariant.body,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          color: option.enabled ? AppColors.ink : AppColors.inkMuted,
        ),
        if (option.subtitle != null)
          AppText(
            option.subtitle!,
            variant: AppTextVariant.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _SearchableDropdown<T> extends StatelessWidget {
  const _SearchableDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    required this.validator,
    required this.enabled,
    required this.helperText,
  });

  final String label;
  final T? value;
  final List<DropdownOption<T>> items;
  final ValueChanged<T?>? onChanged;
  final String hint;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? helperText;

  DropdownOption<T>? get _selected {
    for (final DropdownOption<T> option in items) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _open(BuildContext context, FormFieldState<T> field) async {
    final DropdownOption<T>? result =
        await showModalBottomSheet<DropdownOption<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) => _SearchPickerSheet<T>(
        title: label,
        items: items,
        selected: value,
      ),
    );
    if (result == null) return;
    field.didChange(result.value);
    onChanged?.call(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final DropdownOption<T>? selected = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FieldLabel(label),
        const SizedBox(height: AppSpacing.sm),
        FormField<T>(
          key: ValueKey<T?>(value),
          initialValue: value,
          validator: validator,
          builder: (FormFieldState<T> field) {
            return InkWell(
              onTap: enabled ? () => _open(context, field) : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InputDecorator(
                isEmpty: selected == null,
                decoration: InputDecoration(
                  enabled: enabled,
                  errorText: field.errorText,
                  helperText: helperText,
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                child: selected == null
                    ? AppText(hint, variant: AppTextVariant.body)
                    : _OptionLabel(option: selected),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SearchPickerSheet<T> extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.items,
    required this.selected,
  });

  final String title;
  final List<DropdownOption<T>> items;
  final T? selected;

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  final TextEditingController _query = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<DropdownOption<T>> get _filtered {
    final String search = _search.trim().toLowerCase();
    if (search.isEmpty) return widget.items;
    return widget.items.where((DropdownOption<T> option) {
      final String haystack =
          '${option.label} ${option.subtitle ?? ''}'.toLowerCase();
      return haystack.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownOption<T>> options = _filtered;
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AppText(
                      widget.title,
                      variant: AppTextVariant.title,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (String value) => setState(() => _search = value),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: options.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: AppText(
                          'No matches. Try a different spelling.',
                          variant: AppTextVariant.body,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final DropdownOption<T> option = options[index];
                        final bool isSelected =
                            option.value == widget.selected;
                        return ListTile(
                          enabled: option.enabled,
                          selected: isSelected,
                          title: AppText(
                            option.label,
                            variant: AppTextVariant.body,
                          ),
                          subtitle: option.subtitle == null
                              ? null
                              : AppText(
                                  option.subtitle!,
                                  variant: AppTextVariant.caption,
                                ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: option.enabled
                              ? () => Navigator.of(context).pop(option)
                              : null,
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
