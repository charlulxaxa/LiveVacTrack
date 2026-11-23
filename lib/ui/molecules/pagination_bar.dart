import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    required this.showing,
    required this.limit,
    required this.onLoadMore,
    super.key,
  });

  final int showing;
  final int limit;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (showing == 0) return const SizedBox.shrink();
    final bool hasMore = showing >= limit;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: hasMore
          ? AppButton(
              label: 'Load more',
              onPressed: onLoadMore,
              variant: AppButtonVariant.secondary,
              compact: true,
            )
          : Center(
              child: AppText(
                'Showing all $showing records',
                variant: AppTextVariant.caption,
              ),
            ),
    );
  }
}
