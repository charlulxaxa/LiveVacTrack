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
      // IndexedStack keeps every tab's state alive; each tab is told whether
      // it is the visible one and fades in when it becomes visible.
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          for (int i = 0; i < widget.tabs.length; i++)
            _ShellTabHost(active: i == _index, child: widget.tabs[i].child),
        ],
      ),
      navigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int value) => setState(() => _index = value),
        destinations: widget.tabs
            .map(
              (ShellTab tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon, color: AppColors.primary),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Tells a tab's widgets whether that tab is the one currently shown, so
/// expensive work (such as the camera on the checkpoint scanner) can stop
/// while another tab is open.
class ShellTabScope extends InheritedWidget {
  const ShellTabScope({required this.active, required super.child, super.key});

  final bool active;

  /// True when there is no enclosing [AppShell], so widgets used outside a
  /// shell behave as always visible.
  static bool isActive(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ShellTabScope>()
            ?.active ??
        true;
  }

  @override
  bool updateShouldNotify(ShellTabScope oldWidget) =>
      active != oldWidget.active;
}

class _ShellTabHost extends StatefulWidget {
  const _ShellTabHost({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_ShellTabHost> createState() => _ShellTabHostState();
}

class _ShellTabHostState extends State<_ShellTabHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final CurvedAnimation _opacity = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOut,
  );

  @override
  void didUpdateWidget(_ShellTabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      final bool reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (reduceMotion) {
        _fade.value = 1;
      } else {
        _fade.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellTabScope(
      active: widget.active,
      child: FadeTransition(opacity: _opacity, child: widget.child),
    );
  }
}
