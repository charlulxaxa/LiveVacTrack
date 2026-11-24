import 'package:material_ui/material_ui.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/auth_service.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text_field.dart';
import '../molecules/error_banner.dart';
import '../templates/form_template.dart';

/// Current password, new password and confirmation. The confirmation is
/// re-checked whenever either new-password field changes.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({required this.onSubmit, super.key});

  final Future<void> Function({
    required String currentPassword,
    required String newPassword,
  }) onSubmit;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _new = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _show = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        currentPassword: _current.text,
        newPassword: _new.text,
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _revalidate() {
    // Keep the "passwords do not match" message in step with typing once the
    // confirmation field has content.
    if (_confirm.text.isNotEmpty) _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final Widget visibility = IconButton(
      tooltip: _show ? 'Hide passwords' : 'Show passwords',
      icon: Icon(_show ? Icons.visibility_off_rounded : Icons.visibility_rounded),
      onPressed: () => setState(() => _show = !_show),
    );

    return Form(
      key: _formKey,
      child: FormTemplate(
        title: 'Change password',
        subtitle: 'Enter your current password, then choose a new one.',
        fields: <Widget>[
          if (_error != null) ...<Widget>[
            ErrorBanner(message: _error!),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            controller: _current,
            label: 'Current password',
            obscureText: !_show,
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: visibility,
            textInputAction: TextInputAction.next,
            validator: (String? value) => value == null || value.isEmpty
                ? 'Enter your current password'
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _new,
            label: 'New password',
            hint: 'At least 8 characters',
            obscureText: !_show,
            prefixIcon: Icons.lock_reset_rounded,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _revalidate(),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Enter a new password';
              }
              return validateNewPassword(
                value,
                currentPassword: _current.text.isEmpty ? null : _current.text,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _confirm,
            label: 'Confirm new password',
            obscureText: !_show,
            prefixIcon: Icons.lock_reset_rounded,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _revalidate(),
            onFieldSubmitted: (_) => _submit(),
            validator: (String? value) {
              if (value == null || value.isEmpty) {
                return 'Re-enter the new password';
              }
              if (value != _new.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
        footer: AppButton(
          label: 'Change password',
          onPressed: _submit,
          loading: _submitting,
          icon: Icons.check_rounded,
        ),
      ),
    );
  }
}
