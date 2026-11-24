import 'package:material_ui/material_ui.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../atoms/app_button.dart';
import '../atoms/app_text.dart';
import '../atoms/app_text_field.dart';
import '../molecules/error_banner.dart';

class LoginDemoCredential {
  const LoginDemoCredential({
    required this.email,
    required this.roleLabel,
    required this.name,
  });

  final String email;
  final String roleLabel;
  final String name;
}

class LoginForm extends StatefulWidget {
  const LoginForm({
    required this.onSubmit,
    super.key,
    this.demoCredentials = const <LoginDemoCredential>[],
    this.demoPassword = '',
  });

  final Future<void> Function(String email, String password) onSubmit;
  final List<LoginDemoCredential> demoCredentials;
  final String demoPassword;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_email.text.trim(), _password.text);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Sign in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useDemo(LoginDemoCredential credential) async {
    _email.text = credential.email;
    _password.text = widget.demoPassword;
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppText('Sign in', variant: AppTextVariant.title),
              const SizedBox(height: 4),
              AppText(
                'Use the account issued by the vet office. There is no public sign-up.',
                variant: AppTextVariant.caption,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _email,
                label: 'Email',
                hint: 'name@livevactrack.test',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _password,
                label: 'Password',
                hint: 'Minimum 8 characters',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.lg),
                ErrorBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Sign in',
                onPressed: _submit,
                loading: _loading,
                icon: Icons.login_rounded,
              ),
              if (widget.demoCredentials.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: AppText(
                        'DEMO ACCOUNTS',
                        variant: AppTextVariant.caption,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: widget.demoCredentials
                      .map((LoginDemoCredential credential) => ActionChip(
                            label: AppText(
                              credential.roleLabel,
                              variant: AppTextVariant.caption,
                              fontWeight: FontWeight.w600,
                            ),
                            onPressed: _loading
                                ? null
                                : () => _useDemo(credential),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppText(
                  'Password for all demo accounts: ${widget.demoPassword}',
                  variant: AppTextVariant.caption,
                  color: AppColors.inkMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
