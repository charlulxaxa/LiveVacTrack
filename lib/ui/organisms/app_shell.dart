import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_badge.dart';
import '../templates/shell_template.dart';

class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.title,
    required this.tabs,
    super.key,
    this.offline = false,
    this.actions = const <Widget>[],
    this.initialIndex = 0,
  });

  final String title;
  final List<ShellTab> tabs;
  final bool offline;
  final List<Widget> actions;
  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex.clamp(0, widget.tabs.length - 1);

  @override
  Widget build(BuildContext context) {
    return ShellTemplate(
      title: widget.title,
      actions: <Widget>[
        if (widget.offline)
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: AppBadge(
              label: 'Offline',
              tone: BadgeTone.warning,
              icon: Icons.cloud_off_rounded,
              dense: true,
            ),
          ),
        ...widget.actions,
      ],
      body: IndexedStack(
        index: _index,
        children: widget.tabs.map((ShellTab tab) => tab.child).toList(),
      ),
      navigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: widget.tabs
            .map((ShellTab tab) => NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon, color: AppColors.primary),
                  label: tab.label,
                ))
            .toList(),
      ),
    );
  }
}
