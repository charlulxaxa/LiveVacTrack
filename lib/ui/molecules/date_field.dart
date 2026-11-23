import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_utils.dart';
import '../atoms/app_text.dart';

class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.firstDate,
    this.lastDate,
    this.errorText,
    this.helperText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppText(
          label,
          variant: AppTextVariant.label,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: firstDate ?? DateTime(now.year - 1),
              lastDate: lastDate ?? DateTime(now.year + 5),
            );
            if (picked != null) onChanged(picked);
          },
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: errorText,
              helperText: helperText,
              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
            ),
            child: AppText(
              formatDate(value),
              variant: AppTextVariant.body,
              color: value == null ? AppColors.inkMuted : AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
