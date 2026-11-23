import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../atoms/app_text.dart';

class LastSyncedLabel extends StatelessWidget {
  const LastSyncedLabel({
    required this.lastSynced,
    super.key,
    this.offline = false,
  });

  final DateTime? lastSynced;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          offline ? Icons.cloud_off_rounded : Icons.sync_rounded,
          size: 13,
          color: offline ? AppColors.warning : AppColors.inkMuted,
        ),
        const SizedBox(width: 4),
        AppText(
          lastSyncedLabel(lastSynced),
          variant: AppTextVariant.caption,
          color: offline ? AppColors.warning : AppColors.inkMuted,
        ),
      ],
    );
  }
}
