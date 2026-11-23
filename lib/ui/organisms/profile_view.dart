import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/app_user.dart';
import '../atoms/app_avatar.dart';
import '../atoms/app_badge.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../molecules/info_row.dart';
import '../molecules/section_header.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    required this.user,
    required this.demoMode,
    required this.offlineSimulated,
    required this.onOfflineChanged,
    required this.onSignOut,
    super.key,
  });

  final AppUser user;
  final bool demoMode;
  final bool offlineSimulated;
  final ValueChanged<bool> onOfflineChanged;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                AppAvatar(initials: user.initials, size: 56),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppText(user.displayName, variant: AppTextVariant.title),
                      const SizedBox(height: 2),
                      AppText(user.role.label, variant: AppTextVariant.caption),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: <Widget>[
                          AppBadge(
                            label: demoMode ? 'Demo mode' : 'Live Firebase',
                            tone: demoMode ? BadgeTone.info : BadgeTone.success,
                          ),
                          if (user.areaId != null)
                            AppBadge(
                              label: user.areaName ??
                                  AppConfig.areaName(user.areaId!),
                              tone: BadgeTone.neutral,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(
          title: 'Field tools',
          subtitle: 'Useful when demonstrating weak-signal behaviour',
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: SwitchListTile(
            value: offlineSimulated,
            onChanged: onOfflineChanged,
            activeTrackColor: AppColors.primary,
            title: AppText(
              'Simulate offline mode',
              variant: AppTextVariant.body,
              fontWeight: FontWeight.w600,
            ),
            subtitle: AppText(
              'Forces the checkpoint screen to show cached, unverified results.',
              variant: AppTextVariant.caption,
            ),
            secondary: const Icon(Icons.cloud_off_rounded,
                color: AppColors.warning),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Account'),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: <Widget>[
                InfoRow(label: 'User ID', value: user.id),
                const Divider(height: 1),
                InfoRow(label: 'Role', value: user.role.label),
                const Divider(height: 1),
                InfoRow(
                  label: 'Area',
                  value: user.areaId == null
                      ? 'Not assigned'
                      : user.areaName ?? AppConfig.areaName(user.areaId!),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Sign out',
          onPressed: onSignOut,
          variant: AppButtonVariant.secondary,
          icon: Icons.logout_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: AppText(
            '${AppConfig.appName} · CC105 Groupata',
            variant: AppTextVariant.caption,
          ),
        ),
      ],
    );
  }
}
