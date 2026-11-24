import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_spacing.dart';
import '../atoms/app_chip.dart';

class FilterOption {
  const FilterOption({
    required this.key,
    required this.label,
    this.count,
  });

  final String key;
  final String label;
  final int? count;
}

class StatusFilterBar extends StatelessWidget {
  const StatusFilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<FilterOption> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < options.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            AppChip(
              label: options[i].label,
              count: options[i].count,
              selected: selected == options[i].key,
              onSelected: () => onSelected(options[i].key),
            ),
          ],
        ],
      ),
    );
  }
}
