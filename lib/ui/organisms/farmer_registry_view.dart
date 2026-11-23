import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/models/farmer.dart';
import '../atoms/app_button.dart';
import '../atoms/app_spinner.dart';
import '../molecules/empty_state.dart';
import '../molecules/error_banner.dart';
import '../molecules/farmer_list_tile.dart';
import '../molecules/pagination_bar.dart';
import '../molecules/search_field.dart';
import '../templates/list_template.dart';

class FarmerRegistryView extends StatefulWidget {
  const FarmerRegistryView({
    required this.farmers,
    required this.loading,
    required this.limit,
    required this.onLoadMore,
    super.key,
    this.error,
    this.onAdd,
    this.onTap,
    this.onRefresh,
  });

  final List<Farmer> farmers;
  final bool loading;
  final String? error;
  final int limit;
  final VoidCallback onLoadMore;
  final VoidCallback? onAdd;
  final ValueChanged<Farmer>? onTap;
  final Future<void> Function()? onRefresh;

  @override
  State<FarmerRegistryView> createState() => _FarmerRegistryViewState();
}

class _FarmerRegistryViewState extends State<FarmerRegistryView> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Farmer> get _filtered {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.farmers;
    return widget.farmers.where((Farmer farmer) {
      return farmer.fullName.toLowerCase().contains(query) ||
          farmer.barangay.toLowerCase().contains(query) ||
          (farmer.contactNo?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Farmer> rows = _filtered;
    final Widget body;

    if (widget.loading && widget.farmers.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: AppSpinner()),
      );
    } else if (widget.error != null && widget.farmers.isEmpty) {
      body = ErrorBanner(message: widget.error!);
    } else if (rows.isEmpty) {
      body = EmptyState(
        title: _query.isEmpty ? 'No farmers yet' : 'No matches',
        message: _query.isEmpty
            ? 'Register the first livestock owner to begin.'
            : 'Try a different name, barangay or contact number.',
        icon: Icons.people_outline_rounded,
        actionLabel: _query.isEmpty ? 'Register farmer' : null,
        onAction: _query.isEmpty ? widget.onAdd : null,
      );
    } else {
      body = Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            FarmerListTile(
              farmer: rows[i],
              onTap: widget.onTap == null
                  ? null
                  : () => widget.onTap!(rows[i]),
            ),
          ],
          PaginationBar(
            showing: widget.farmers.length,
            limit: widget.limit,
            onLoadMore: widget.onLoadMore,
          ),
        ],
      );
    }

    final Widget content = ListTemplate(
      title: 'Farmers',
      subtitle: '${widget.farmers.length} registered livestock owners',
      action: widget.onAdd == null
          ? null
          : AppButton(
              label: 'Add',
              onPressed: widget.onAdd,
              icon: Icons.person_add_alt_1_rounded,
              compact: true,
              expand: false,
            ),
      controls: SearchField(
        controller: _search,
        hint: 'Search name, barangay or contact',
        onChanged: (String value) => setState(() => _query = value),
      ),
      child: body,
    );

    if (widget.onRefresh == null) return content;
    return RefreshIndicator(
      onRefresh: widget.onRefresh!,
      child: content,
    );
  }
}
