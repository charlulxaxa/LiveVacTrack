import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/enums/permit_status.dart';
import '../../data/models/animal.dart';
import '../../data/models/permit.dart';
import '../atoms/app_skeleton.dart';
import '../molecules/empty_state.dart';
import '../molecules/error_banner.dart';
import '../molecules/pagination_bar.dart';
import '../molecules/permit_list_tile.dart';
import '../molecules/search_field.dart';
import '../molecules/status_filter_bar.dart';
import '../templates/list_template.dart';

class PermitListView extends StatefulWidget {
  const PermitListView({
    required this.permits,
    required this.animals,
    required this.loading,
    required this.limit,
    required this.onLoadMore,
    super.key,
    this.error,
    this.onTap,
    this.onRefresh,
  });

  final List<Permit> permits;
  final List<Animal> animals;
  final bool loading;
  final String? error;
  final int limit;
  final VoidCallback onLoadMore;
  final ValueChanged<Permit>? onTap;
  final Future<void> Function()? onRefresh;

  @override
  State<PermitListView> createState() => _PermitListViewState();
}

class _PermitListViewState extends State<PermitListView> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String? _tagFor(String animalId) {
    for (final Animal animal in widget.animals) {
      if (animal.id == animalId) return animal.tagNo;
    }
    return null;
  }

  List<Permit> get _filtered {
    final String query = _query.trim().toLowerCase();
    return widget.permits.where((Permit permit) {
      final PermitStatus status = permit.effectiveStatus();
      final bool matchesFilter = _filter == 'all' || status.wire == _filter;
      final bool matchesQuery =
          query.isEmpty ||
          permit.id.toLowerCase().contains(query) ||
          permit.origin.toLowerCase().contains(query) ||
          permit.destination.toLowerCase().contains(query) ||
          (_tagFor(permit.animalId)?.toLowerCase().contains(query) ?? false);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  int _count(String key) {
    if (key == 'all') return widget.permits.length;
    return widget.permits
        .where((Permit permit) => permit.effectiveStatus().wire == key)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final List<Permit> rows = _filtered;
    final Widget body;

    if (widget.loading && widget.permits.isEmpty) {
      body = const SkeletonList();
    } else if (widget.error != null && widget.permits.isEmpty) {
      body = ErrorBanner(message: widget.error!);
    } else if (rows.isEmpty) {
      body = const EmptyState(
        title: 'No permits found',
        message: 'Permits issued by the clerk will appear here.',
        icon: Icons.description_outlined,
      );
    } else {
      body = Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            PermitListTile(
              permit: rows[i],
              animalTag: _tagFor(rows[i].animalId),
              onTap: widget.onTap == null ? null : () => widget.onTap!(rows[i]),
            ),
          ],
          PaginationBar(
            showing: widget.permits.length,
            limit: widget.limit,
            onLoadMore: widget.onLoadMore,
          ),
        ],
      );
    }

    final Widget content = ListTemplate(
      title: 'Permits',
      subtitle: '${widget.permits.length} movement permits',
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SearchField(
            controller: _search,
            hint: 'Search permit, route or animal tag',
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          StatusFilterBar(
            selected: _filter,
            onSelected: (String key) => setState(() => _filter = key),
            options: <FilterOption>[
              FilterOption(key: 'all', label: 'All', count: _count('all')),
              FilterOption(
                key: PermitStatus.issued.wire,
                label: 'Issued',
                count: _count(PermitStatus.issued.wire),
              ),
              FilterOption(
                key: PermitStatus.revoked.wire,
                label: 'Revoked',
                count: _count(PermitStatus.revoked.wire),
              ),
              FilterOption(
                key: PermitStatus.expired.wire,
                label: 'Expired',
                count: _count(PermitStatus.expired.wire),
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
