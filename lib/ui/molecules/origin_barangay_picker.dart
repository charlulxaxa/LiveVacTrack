import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/services/psgc_location_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../state/repository_providers.dart';
import '../atoms/app_text.dart';
import 'dropdown_field.dart';
import 'error_banner.dart';

/// Origin dropdown for the permit officer: only the barangays of the city or
/// municipality the officer is assigned to.
///
/// Official accounts are assigned a PSGC barangay code, so their city's
/// barangays come from the PSGC service. Demo accounts use the demo areas.
class OriginBarangayPicker extends ConsumerStatefulWidget {
  const OriginBarangayPicker({
    required this.assignedAreaId,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The officer's own area (`AppUser.areaId`).
  final String? assignedAreaId;

  /// Selected barangay id (PSGC code or demo area id).
  final String? value;

  /// Called with the barangay id and the text to store as the permit origin.
  final void Function(String? id, String? label) onChanged;

  @override
  ConsumerState<OriginBarangayPicker> createState() =>
      _OriginBarangayPickerState();
}

class _OriginBarangayPickerState extends ConsumerState<OriginBarangayPicker> {
  List<DropdownOption<String>> _options = <DropdownOption<String>>[];
  Map<String, String> _labels = <String, String>{};
  String? _cityName;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(OriginBarangayPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assignedAreaId != widget.assignedAreaId) _load();
  }

  Future<void> _load() async {
    final String? cityCode =
        PsgcLocationService.cityCodeForBarangay(widget.assignedAreaId);

    if (cityCode == null) {
      // Demo areas (or no assigned area at all).
      final bool hasArea = widget.assignedAreaId != null &&
          widget.assignedAreaId!.isNotEmpty;
      setState(() {
        _cityName = null;
        _error = hasArea
            ? null
            : 'Your account has no assigned area. Ask the super admin to set '
                'one before issuing permits.';
        _labels = <String, String>{
          if (hasArea)
            for (final AreaOption area in AppConfig.areas) area.id: area.name,
        };
        _options = _labels.entries
            .map((MapEntry<String, String> e) =>
                DropdownOption<String>(value: e.key, label: e.value))
            .toList();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<PsgcBarangay> barangays =
          await ref.read(psgcLocationServiceProvider).fetchBarangays(cityCode);
      if (!mounted) return;
      final String? city =
          barangays.isEmpty ? null : barangays.first.cityMunicipality;
      setState(() {
        _cityName = city;
        _labels = <String, String>{
          for (final PsgcBarangay b in barangays)
            b.code: <String>[
              b.name,
              if (b.cityMunicipality.isNotEmpty) b.cityMunicipality,
            ].join(', '),
        };
        _options = barangays
            .map((PsgcBarangay b) =>
                DropdownOption<String>(value: b.code, label: b.name))
            .toList();
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? selected =
        _labels.containsKey(widget.value) ? widget.value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_error != null) ...<Widget>[
          ErrorBanner(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        DropdownField<String>(
          label: 'Origin barangay',
          value: selected,
          searchable: _options.length > 10,
          enabled: !_loading && _options.isNotEmpty,
          hint: _loading ? 'Loading barangays…' : 'Select the origin barangay',
          helperText: _cityName == null
              ? 'Barangays in your assigned area.'
              : 'Barangays in $_cityName, your assigned area.',
          items: _options,
          onChanged: (String? id) =>
              widget.onChanged(id, id == null ? null : _labels[id]),
          validator: (String? value) =>
              value == null ? 'Select the origin barangay' : null,
        ),
        if (_loading) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          AppText('Loading barangays…', variant: AppTextVariant.caption),
        ],
      ],
    );
  }
}
