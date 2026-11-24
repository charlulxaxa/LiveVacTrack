import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/quarantine.dart';
import '../atoms/app_button.dart';
import '../atoms/app_skeleton.dart';
import '../atoms/app_text.dart';
import '../molecules/empty_state.dart';
import '../molecules/error_banner.dart';
import '../molecules/quarantine_tile.dart';
import '../molecules/status_filter_bar.dart';
import '../templates/list_template.dart';

class QuarantineListView extends StatefulWidget {
  const QuarantineListView({
    required this.quarantines,
    required this.loading,
    super.key,
    this.error,
    this.onDeclare,
    this.onActivate,
    this.onLift,
    this.onRefresh,
  });

  final List<Quarantine> quarantines;
  final bool loading;
  final String? error;
  final VoidCallback? onDeclare;
  final Future<void> Function(Quarantine quarantine)? onActivate;
  final Future<void> Function(Quarantine quarantine)? onLift;
  final Future<void> Function()? onRefresh;

  @override
  State<QuarantineListView> createState() => _QuarantineListViewState();
}

class _QuarantineListViewState extends State<QuarantineListView> {
  String _filter = 'all';

  List<Quarantine> get _filtered {
    if (_filter == 'all') return widget.quarantines;
    return widget.quarantines.where((Quarantine q) {
      return _filter == 'active' ? q.isActive : !q.isActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Quarantine> active = widget.quarantines
        .where((Quarantine q) => q.isActive)
        .toList();
    final List<Quarantine> rows = _filtered;

    final Widget body;
    if (widget.loading && widget.quarantines.isEmpty) {
      body = const SkeletonList();
    } else if (widget.error != null && widget.quarantines.isEmpty) {
      body = ErrorBanner(message: widget.error!);
    } else if (rows.isEmpty) {
      body = const EmptyState(
        title: 'No quarantine alerts',
        message: 'Active and lifted quarantines will appear here.',
        icon: Icons.health_and_safety_outlined,
      );
    } else {
      body = Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            QuarantineTile(
              quarantine: rows[i],
              onActivate: widget.onActivate != null && !rows[i].isActive
                  ? () => widget.onActivate!(rows[i])
                  : null,
              onLift: widget.onLift != null && rows[i].isActive
                  ? () => widget.onLift!(rows[i])
                  : null,
            ),
          ],
        ],
      );
    }

    final Widget content = ListTemplate(
      title: 'Quarantine alerts',
      subtitle: active.isEmpty
          ? 'No active quarantines'
          : '${active.length} active area quarantine(s)',
      action: widget.onDeclare == null
          ? null
          : AppButton(
              label: 'Declare',
              onPressed: widget.onDeclare,
              icon: Icons.add_alert_rounded,
              compact: true,
              expand: false,
            ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (active.isNotEmpty) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(
                      'Permits in quarantined areas are revoked and new permits are blocked.',
                      variant: AppTextVariant.caption,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          StatusFilterBar(
            selected: _filter,
            onSelected: (String key) => setState(() => _filter = key),
            options: <FilterOption>[
              FilterOption(
                key: 'all',
                label: 'All',
                count: widget.quarantines.length,
              ),
              FilterOption(
                key: 'active',
                label: 'Active',
                count: active.length,
              ),
              FilterOption(
                key: 'lifted',
                label: 'Lifted',
                count: widget.quarantines.length - active.length,
              ),
            ],
          ),
        ],
      ),
      child: body,
    );

    if (widget.onRefresh == null) return content;
    return RefreshIndicator(onRefresh: widget.onRefresh!, child: content);
  }
}
