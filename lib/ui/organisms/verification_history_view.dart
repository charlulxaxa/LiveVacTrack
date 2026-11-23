import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/verification.dart';
import '../atoms/app_spinner.dart';
import '../molecules/empty_state.dart';
import '../molecules/error_banner.dart';
import '../molecules/verification_tile.dart';
import '../templates/list_template.dart';

class VerificationHistoryView extends StatelessWidget {
  const VerificationHistoryView({
    required this.verifications,
    required this.loading,
    super.key,
    this.error,
  });

  final List<Verification> verifications;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (loading && verifications.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: AppSpinner()),
      );
    } else if (error != null && verifications.isEmpty) {
      body = ErrorBanner(message: error!);
    } else if (verifications.isEmpty) {
      body = const EmptyState(
        title: 'No scans yet',
        message: 'Permits you verify will be logged here.',
        icon: Icons.history_rounded,
      );
    } else {
      body = Column(
        children: <Widget>[
          for (int i = 0; i < verifications.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            VerificationTile(verification: verifications[i]),
          ],
        ],
      );
    }

    return ListTemplate(
      title: 'Scan history',
      subtitle: '${verifications.length} verification log entries',
      child: body,
    );
  }
}
