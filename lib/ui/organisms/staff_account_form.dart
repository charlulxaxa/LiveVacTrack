import 'package:material_ui/material_ui.dart';

import '../../core/services/psgc_location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/dropdown_field.dart';
import '../molecules/error_banner.dart';
import '../molecules/location_picker.dart';
import '../templates/form_template.dart';

class StaffRoleOption {
  const StaffRoleOption(this.wire, this.label);

  final String wire;
  final String label;
}

const List<StaffRoleOption> staffRoles = <StaffRoleOption>[
  StaffRoleOption('registry', 'Registry staff'),
  StaffRoleOption('vet', 'Veterinarian'),
  StaffRoleOption('clerk', 'Permit clerk'),
  StaffRoleOption('inspector', 'Checkpoint inspector'),
  StaffRoleOption('disease_control', 'Disease control officer'),
];

class StaffAccountForm extends StatefulWidget {
  const StaffAccountForm({required this.onSubmit, super.key});

  final Future<void> Function({
    required String email,
    required String password,
    required String displayName,
    required String role,
    required String areaId,
    required String areaName,
  }) onSubmit;

  @override
  State<StaffAccountForm> createState() => _StaffAccountFormState();
}

class _StaffAccountFormState extends State<StaffAccountForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  String? _role;
  String? _areaId;
  String? _areaName;
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_role == null || _areaId == null) {
      setState(() {
        _error = 'Select a role and an area.';
        _success = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });

    try {
      await widget.onSubmit(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _name.text.trim(),
        role: _role!,
        areaId: _areaId!,
        areaName: _areaName ?? _areaId!,
      );
      if (!mounted) return;
      setState(() {
        _success = 'Account created for ${_email.text.trim().toLowerCase()}.';
        _name.clear();
        _email.clear();
        _password.clear();
        _confirm.clear();
        _role = null;
        _areaId = null;
        _areaName = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: FormTemplate(
        title: 'Create staff account',
        subtitle:
            'Accounts are provisioned with the selected role. The user signs '
            'in with their email and password.',
        fields: <Widget>[
          if (_error != null) ...<Widget>[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (_success != null) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(
                      _success!,
                      variant: AppTextVariant.caption,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            controller: _name,
            label: 'Display name',
            hint: 'e.g. Carla Dizon',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (String? value) =>
                value == null || value.trim().isEmpty
                    ? 'Display name is required'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _email,
            label: 'Email',
            hint: 'name@livevactrack.test',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (String? value) {
              final String email = value?.trim().toLowerCase() ?? '';
              if (email.isEmpty) return 'Email is required';
              if (!email.contains('@') || !email.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          DropdownField<String>(
            label: 'Role',
            value: _role,
            hint: 'Select a staff role',
            items: staffRoles
                .map((StaffRoleOption role) => DropdownOption<String>(
                      value: role.wire,
                      label: role.label,
                    ))
                .toList(),
            onChanged: (String? value) => setState(() => _role = value),
            validator: (String? value) =>
                value == null ? 'Select a role' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          LocationPicker(
            label: 'Area',
            onChanged: (AreaSelection? selection) {
              setState(() {
                _areaId = selection?.id;
                _areaName = selection?.fullName;
              });
            },
            validator: (AreaSelection? value) =>
                value == null ? 'Select an area' : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _password,
            label: 'Password',
            hint: 'At least 8 characters',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: (String? value) =>
                value == null || value.length < 8
                    ? 'Password must be at least 8 characters'
                    : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _confirm,
            label: 'Confirm password',
            hint: 'Re-enter the password',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (String? value) =>
                value != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppText(
            'Only the super admin can create accounts.',
            variant: AppTextVariant.caption,
          ),
        ],
        footer: AppButton(
          label: 'Create account',
          onPressed: _submit,
          loading: _submitting,
          icon: Icons.person_add_rounded,
        ),
      ),
    );
  }
}
