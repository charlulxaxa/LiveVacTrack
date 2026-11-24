import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/psgc_location_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../state/repository_providers.dart';
import '../atoms/app_text.dart';
import 'dropdown_field.dart';
import 'error_banner.dart';

/// Region -> city/municipality -> barangay, covering the whole country.
///
/// It starts from the region rather than the province because some cities
/// (all of Metro Manila, Cotabato City, Isabela City) are not under any
/// province in the PSGC.
class NationwideLocationPicker extends ConsumerStatefulWidget {
  const NationwideLocationPicker({
    required this.onChanged,
    super.key,
    this.label = 'Barangay',
  });

  final ValueChanged<AreaSelection?> onChanged;
  final String label;

  @override
  ConsumerState<NationwideLocationPicker> createState() =>
      _NationwideLocationPickerState();
}

class _NationwideLocationPickerState
    extends ConsumerState<NationwideLocationPicker> {
  List<PsgcRegion> _regions = <PsgcRegion>[];
  List<PsgcCity> _cities = <PsgcCity>[];
  List<PsgcBarangay> _barangays = <PsgcBarangay>[];

  String? _regionCode;
  String? _cityCode;
  String? _barangayCode;

  bool _loadingRegions = false;
  bool _loadingCities = false;
  bool _loadingBarangays = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _loadingRegions = true;
      _error = null;
    });
    try {
      final List<PsgcRegion> regions =
          await ref.read(psgcLocationServiceProvider).fetchRegions();
      if (mounted) setState(() => _regions = regions);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  Future<void> _loadCities(String regionCode) async {
    setState(() {
      _loadingCities = true;
      _error = null;
      _cities = <PsgcCity>[];
      _barangays = <PsgcBarangay>[];
      _cityCode = null;
      _barangayCode = null;
    });
    try {
      final List<PsgcCity> cities = await ref
          .read(psgcLocationServiceProvider)
          .fetchRegionCities(regionCode);
      cities.sort((PsgcCity a, PsgcCity b) =>
          a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()));
      if (mounted) setState(() => _cities = cities);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _loadBarangays(String cityCode) async {
    setState(() {
      _loadingBarangays = true;
      _error = null;
      _barangays = <PsgcBarangay>[];
      _barangayCode = null;
    });
    try {
      final List<PsgcBarangay> barangays = await ref
          .read(psgcLocationServiceProvider)
          .fetchBarangays(cityCode);
      if (mounted) setState(() => _barangays = barangays);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingBarangays = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PsgcCity? city =
        _cities.where((PsgcCity c) => c.code == _cityCode).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_error != null) ...<Widget>[
          ErrorBanner(message: _error!),
          const SizedBox(height: AppSpacing.md),
        ],
        DropdownField<String>(
          label: 'Region',
          value: _regionCode,
          searchable: true,
          hint: _loadingRegions ? 'Loading regions…' : 'Select a region',
          enabled: !_loadingRegions && _regions.isNotEmpty,
          items: _regions
              .map((PsgcRegion r) =>
                  DropdownOption<String>(value: r.code, label: r.name))
              .toList(),
          onChanged: (String? code) {
            setState(() => _regionCode = code);
            widget.onChanged(null);
            if (code != null) _loadCities(code);
          },
          validator: (String? value) =>
              value == null ? 'Select a region' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownField<String>(
          label: 'City / Municipality',
          value: _cityCode,
          searchable: true,
          hint: _loadingCities
              ? 'Loading cities…'
              : _regionCode == null
                  ? 'Select a region first'
                  : 'Select a city or municipality',
          enabled:
              !_loadingCities && _regionCode != null && _cities.isNotEmpty,
          items: _cities
              .map((PsgcCity c) => DropdownOption<String>(
                    value: c.code,
                    label: c.name.trim(),
                    subtitle: <String>[
                      c.type == 'Mun' ? 'Municipality' : c.type,
                      if (c.province.isNotEmpty) c.province,
                    ].join(' · '),
                  ))
              .toList(),
          onChanged: (String? code) {
            setState(() => _cityCode = code);
            widget.onChanged(null);
            if (code != null) _loadBarangays(code);
          },
          validator: (String? value) =>
              value == null ? 'Select a city or municipality' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownField<String>(
          label: widget.label,
          value: _barangayCode,
          searchable: true,
          hint: _loadingBarangays
              ? 'Loading barangays…'
              : _cityCode == null
                  ? 'Select a city or municipality first'
                  : 'Select a barangay',
          enabled: !_loadingBarangays &&
              _cityCode != null &&
              _barangays.isNotEmpty,
          items: _barangays
              .map((PsgcBarangay b) =>
                  DropdownOption<String>(value: b.code, label: b.name))
              .toList(),
          onChanged: (String? code) {
            setState(() => _barangayCode = code);
            if (code == null) {
              widget.onChanged(null);
              return;
            }
            final PsgcBarangay barangay =
                _barangays.firstWhere((PsgcBarangay b) => b.code == code);
            widget.onChanged(
              AreaSelection(
                id: barangay.code,
                name: barangay.name,
                city: city?.name.trim(),
                province: (city?.province.isNotEmpty ?? false)
                    ? city!.province
                    : null,
              ),
            );
          },
          validator: (String? value) =>
              value == null ? 'Select a barangay' : null,
        ),
        if (_loadingRegions || _loadingCities || _loadingBarangays) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          AppText('Loading locations…', variant: AppTextVariant.caption),
        ],
      ],
    );
  }
}
