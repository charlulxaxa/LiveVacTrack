import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Template: app bar + body + bottom navigation. The [AppShell] organism owns
/// the tab state and feeds this template.
class ShellTemplate extends StatelessWidget {
  const ShellTemplate({
    required this.title,
    required this.body,
    required this.navigationBar,
    super.key,
    this.actions,
    this.leading,
  });

  final String title;
  final Widget body;
  final Widget navigationBar;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: leading,
        title: Text(title),
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: navigationBar,
      ),
    );
  }
}
