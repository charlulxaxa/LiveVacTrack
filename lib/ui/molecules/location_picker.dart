import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/services/psgc_location_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../state/app_providers.dart';
import '../../state/repository_providers.dart';
import '../atoms/app_text.dart';
import 'dropdown_field.dart';
import 'error_banner.dart';

/// Cascading Philippine location picker (province -> city/municipality ->
/// barangay). Demo mode falls back to the seeded [AppConfig.areas].
class LocationPicker extends ConsumerStatefulWidget {
  const LocationPicker({
    required this.onChanged,
    super.key,
    this.value,
    this.label = 'Area',
    this.validator,
  });

  final AreaSelection? value;
  final ValueChanged<AreaSelection?> onChanged;
  final String label;
  final String? Function(AreaSelection?)? validator;

  @override
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  List<PsgcProvince> _provinces = <PsgcProvince>[];
  List<PsgcCity> _cities = <PsgcCity>[];
  List<PsgcBarangay> _barangays = <PsgcBarangay>[];

  String? _provinceCode;
  String? _cityCode;
  String? _barangayCode;

  bool _loadingProvinces = false;
  bool _loadingCities = false;
  bool _loadingBarangays = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!ref.read(demoModeProvider)) {
      _loadProvinces();
    }
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _loadingProvinces = true;
      _error = null;
    });
    try {
      final List<PsgcProvince> provinces =
          await ref.read(psgcLocationServiceProvider).fetchProvinces();
      if (!mounted) return;
      setState(() => _provinces = provinces);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadCities(String provinceCode) async {
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
          .fetchCities(provinceCode);
      if (!mounted) return;
      setState(() => _cities = cities);
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
      if (!mounted) return;
      setState(() => _barangays = barangays);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loadingBarangays = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(demoModeProvider)) {
      return _demoPicker();
    }

    final PsgcProvince? province = _provinces
        .where((PsgcProvince p) => p.code == _provinceCode)
        .firstOrNull;
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
          label: 'Province',
          value: _provinceCode,
          searchable: true,
          hint: _loadingProvinces ? 'Loading provinces…' : 'Select a province',
          enabled: !_loadingProvinces && _provinces.isNotEmpty,
          items: _provinces
              .map((PsgcProvince p) => DropdownOption<String>(
                    value: p.code,
                    label: p.name,
                    subtitle: p.region,
                  ))
              .toList(),
          onChanged: (String? code) {
            setState(() => _provinceCode = code);
            widget.onChanged(null);
            if (code != null) _loadCities(code);
          },
          validator: (String? value) =>
              value == null ? 'Select a province' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownField<String>(
          label: 'City / Municipality',
          value: _cityCode,
          searchable: true,
          hint: _loadingCities
              ? 'Loading cities…'
              : _provinceCode == null
                  ? 'Select a province first'
                  : 'Select a city or municipality',
          enabled:
              !_loadingCities && _provinceCode != null && _cities.isNotEmpty,
          items: _cities
              .map((PsgcCity c) => DropdownOption<String>(
                    value: c.code,
                    label: c.name,
                    subtitle: c.type,
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
              .map((PsgcBarangay b) => DropdownOption<String>(
                    value: b.code,
                    label: b.name,
                  ))
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
                city: city?.name,
                province: province?.name,
              ),
            );
          },
          validator: (String? value) => widget.validator == null
              ? (value == null ? 'Select a barangay' : null)
              : widget.validator!(
                  value == null
                      ? null
                      : AreaSelection(
                          id: value,
                          name: _barangays
                              .firstWhere((PsgcBarangay b) => b.code == value)
                              .name,
                          city: city?.name,
                          province: province?.name,
                        ),
                ),
        ),
        if (_loadingProvinces || _loadingCities || _loadingBarangays) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          AppText(
            'Loading locations…',
            variant: AppTextVariant.caption,
          ),
        ],
      ],
    );
  }

  Widget _demoPicker() {
    return DropdownField<String>(
      label: widget.label,
      value: widget.value?.id,
      hint: 'Select a barangay',
      items: AppConfig.areas
          .map((AreaOption area) => DropdownOption<String>(
                value: area.id,
                label: area.name,
              ))
          .toList(),
      onChanged: (String? id) {
        if (id == null) {
          widget.onChanged(null);
          return;
        }
        final AreaOption area =
            AppConfig.areas.firstWhere((AreaOption a) => a.id == id);
        widget.onChanged(AreaSelection(id: area.id, name: area.name));
      },
      validator: (String? value) {
        final AreaSelection? selection =
            value == null ? null : AreaSelection(id: value, name: value);
        return widget.validator == null
            ? (value == null ? 'Select a barangay' : null)
            : widget.validator!(selection);
      },
    );
  }
}
