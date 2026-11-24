import 'package:material_ui/material_ui.dart';

import '../atoms/app_skeleton.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/staff_member.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/app_spinner.dart';
import '../atoms/app_text.dart';
import '../molecules/error_banner.dart';

enum StaffAction { resetPassword, deactivate, reactivate, remove }

/// Super admin view for creating and managing staff accounts.
class StaffAccountView extends StatelessWidget {
  const StaffAccountView({
    required this.staff,
    required this.loading,
    required this.onAdd,
    required this.onAction,
    super.key,
    this.error,
    this.onRetry,
    this.busyIds = const <String>{},
  });

  final List<StaffMember> staff;
  final bool loading;
  final String? error;
  final VoidCallback onAdd;
  final VoidCallback? onRetry;
  final void Function(StaffMember member, StaffAction action) onAction;

  /// Accounts with an action in progress; their menu shows a spinner.
  final Set<String> busyIds;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.badge_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  AppText('Staff accounts', variant: AppTextVariant.title),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'Create registry, vet, clerk, inspector and disease control '
                'accounts. Use the menu on an account to reset its password, '
                'deactivate it or remove it.',
                variant: AppTextVariant.body,
                color: AppColors.inkMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Add staff account',
          onPressed: onAdd,
          icon: Icons.person_add_rounded,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppText(
          staff.isEmpty ? 'Accounts' : 'Accounts (${staff.length})',
          variant: AppTextVariant.label,
          color: AppColors.inkMuted,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (error != null)
          ErrorBanner(message: error!, onRetry: onRetry)
        else if (loading && staff.isEmpty)
          const SkeletonList()
        else if (staff.isEmpty)
          AppText(
            'No staff accounts yet.',
            variant: AppTextVariant.body,
            color: AppColors.inkMuted,
          )
        else
          for (final StaffMember member in staff)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _StaffTile(
                member: member,
                busy: busyIds.contains(member.id),
                onAction: (StaffAction action) => onAction(member, action),
              ),
            ),
        const SizedBox(height: AppSpacing.md),
        AppText(
          'Only the super admin can manage accounts. Farmers are not app '
          'users and do not need an account.',
          variant: AppTextVariant.caption,
        ),
      ],
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.member,
    required this.busy,
    required this.onAction,
  });

  final StaffMember member;
  final bool busy;
  final ValueChanged<StaffAction> onAction;

  @override
  Widget build(BuildContext context) {
    final String details = <String>[
      if (member.email != null && member.email!.isNotEmpty) member.email!,
      if (member.areaName != null && member.areaName!.isNotEmpty)
        member.areaName!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          AppAvatar(
            initials: member.initials,
            color: member.disabled ? AppColors.neutral : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            // The name, details and badges read as one item; the menu
            // button next to it stays separately focusable.
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppText(
                    member.displayName,
                    variant: AppTextVariant.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (details.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    AppText(
                      details,
                      variant: AppTextVariant.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      AppBadge(
                        label: member.role.shortLabel,
                        tone: BadgeTone.info,
                        dense: true,
                      ),
                      if (member.disabled)
                        const AppBadge(
                          label: 'Deactivated',
                          tone: BadgeTone.danger,
                          dense: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: AppSpinner(size: 20),
            )
          else
            PopupMenuButton<StaffAction>(
              tooltip: 'Manage ${member.displayName}',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: onAction,
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<StaffAction>>[
                    const PopupMenuItem<StaffAction>(
                      value: StaffAction.resetPassword,
                      child: _MenuRow(
                        icon: Icons.lock_reset_rounded,
                        label: 'Reset password',
                      ),
                    ),
                    if (member.disabled)
                      const PopupMenuItem<StaffAction>(
                        value: StaffAction.reactivate,
                        child: _MenuRow(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Reactivate',
                        ),
                      )
                    else
                      const PopupMenuItem<StaffAction>(
                        value: StaffAction.deactivate,
                        child: _MenuRow(
                          icon: Icons.block_rounded,
                          label: 'Deactivate',
                        ),
                      ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<StaffAction>(
                      value: StaffAction.remove,
                      child: _MenuRow(
                        icon: Icons.delete_outline_rounded,
                        label: 'Remove account',
                        color: AppColors.danger,
                      ),
                    ),
                  ],
            ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: color ?? AppColors.ink),
        const SizedBox(width: AppSpacing.md),
        AppText(label, variant: AppTextVariant.body, color: color),
      ],
    );
  }
}
