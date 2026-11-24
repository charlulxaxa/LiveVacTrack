import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_spacing.dart';
import '../../data/enums/vax_status.dart';
import '../../data/models/animal.dart';
import '../atoms/app_skeleton.dart';
import '../atoms/app_button.dart';
import '../molecules/animal_list_tile.dart';
import '../molecules/empty_state.dart';
import '../molecules/error_banner.dart';
import '../molecules/pagination_bar.dart';
import '../molecules/search_field.dart';
import '../molecules/status_filter_bar.dart';
import '../templates/list_template.dart';

class AnimalRegistryView extends StatefulWidget {
  const AnimalRegistryView({
    required this.animals,
    required this.loading,
    required this.limit,
    required this.onLoadMore,
    super.key,
    this.error,
    this.onAdd,
    this.onTap,
    this.onRefresh,
    this.title = 'Animals',
    this.subtitle,
    this.addLabel = 'Add',
  });

  final List<Animal> animals;
  final bool loading;
  final String? error;
  final int limit;
  final VoidCallback onLoadMore;
  final VoidCallback? onAdd;
  final ValueChanged<Animal>? onTap;
  final Future<void> Function()? onRefresh;
  final String title;
  final String? subtitle;
  final String addLabel;

  @override
  State<AnimalRegistryView> createState() => _AnimalRegistryViewState();
}

class _AnimalRegistryViewState extends State<AnimalRegistryView> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Animal> get _filtered {
    final String query = _query.trim().toLowerCase();
    return widget.animals.where((Animal animal) {
      final bool matchesQuery =
          query.isEmpty ||
          animal.tagNo.toLowerCase().contains(query) ||
          animal.species.toLowerCase().contains(query) ||
          animal.breed.toLowerCase().contains(query) ||
          animal.farmerName.toLowerCase().contains(query) ||
          animal.barangay.toLowerCase().contains(query);
      final bool matchesFilter =
          _filter == 'all' || animal.vaxStatus.wire == _filter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int _count(String key) {
    if (key == 'all') return widget.animals.length;
    return widget.animals
        .where((Animal animal) => animal.vaxStatus.wire == key)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final List<Animal> rows = _filtered;
    final Widget body;

    if (widget.loading && widget.animals.isEmpty) {
      body = const SkeletonList();
    } else if (widget.error != null && widget.animals.isEmpty) {
      body = ErrorBanner(message: widget.error!);
    } else if (rows.isEmpty) {
      body = EmptyState(
        title: _query.isEmpty && _filter == 'all'
            ? 'No animals yet'
            : 'No matching animals',
        message: _query.isEmpty && _filter == 'all'
            ? 'Register an animal to start tracking vaccinations.'
            : 'Adjust the search or filter to see more records.',
        icon: Icons.pets_outlined,
        actionLabel: _query.isEmpty && _filter == 'all'
            ? widget.addLabel
            : null,
        onAction: _query.isEmpty && _filter == 'all' ? widget.onAdd : null,
      );
    } else {
      body = Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            AnimalListTile(
              animal: rows[i],
              onTap: widget.onTap == null ? null : () => widget.onTap!(rows[i]),
            ),
          ],
          PaginationBar(
            showing: widget.animals.length,
            limit: widget.limit,
            onLoadMore: widget.onLoadMore,
          ),
        ],
      );
    }

    final Widget content = ListTemplate(
      title: widget.title,
      subtitle:
          widget.subtitle ??
          '${widget.animals.length} animals · ${_count(VaxStatus.valid.wire)} currently vaccinated',
      action: widget.onAdd == null
          ? null
          : AppButton(
              label: widget.addLabel,
              onPressed: widget.onAdd,
              icon: Icons.add_rounded,
              compact: true,
              expand: false,
            ),
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SearchField(
            controller: _search,
            hint: 'Search tag, species, farmer or barangay',
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpacing.md),
          StatusFilterBar(
            selected: _filter,
            onSelected: (String key) => setState(() => _filter = key),
            options: <FilterOption>[
              FilterOption(key: 'all', label: 'All', count: _count('all')),
              FilterOption(
                key: VaxStatus.valid.wire,
                label: 'Vaccinated',
                count: _count(VaxStatus.valid.wire),
              ),
              FilterOption(
                key: VaxStatus.expired.wire,
                label: 'Expired',
                count: _count(VaxStatus.expired.wire),
              ),
              FilterOption(
                key: VaxStatus.none.wire,
                label: 'None',
                count: _count(VaxStatus.none.wire),
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
