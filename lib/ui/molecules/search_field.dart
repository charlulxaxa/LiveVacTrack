import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../atoms/app_text_field.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      prefixIcon: Icons.search_rounded,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (BuildContext context, TextEditingValue value, Widget? child) {
          if (value.text.isEmpty) return const SizedBox.shrink();
          return IconButton(
            tooltip: 'Clear search',
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.inkMuted,
            onPressed: () {
              controller.clear();
              onChanged?.call('');
              onClear?.call();
            },
          );
        },
      ),
    );
  }
}
