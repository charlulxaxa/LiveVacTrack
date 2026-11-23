import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Template: detail screen with a scrollable body and an optional action bar.
class DetailTemplate extends StatelessWidget {
  const DetailTemplate({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions,
    this.bottomBar,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: actions,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.xxl,
        ),
        children: <Widget>[child],
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: bottomBar,
              ),
            ),
    );
  }
}
