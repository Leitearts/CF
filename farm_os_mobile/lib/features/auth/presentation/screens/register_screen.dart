import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import 'register_controller.dart';

/// Registration collects only what's required for the account itself.
/// Farm details are collected separately in the Create Farm step
/// (Stage 2/4 "Farm Onboarding" -- do not overwhelm the farmer at registration).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final isEmail = identifier.contains('@');

    ref.read(registerControllerProvider.notifier).submit(
          fullName: _fullNameController.text.trim(),
          email: isEmail ? identifier : null,
          phone: isEmail ? null : identifier,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FormSubmissionState>(registerControllerProvider, (previous, next) {
      if (next is FormError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.failure.message)),
        );
      }
      // FormSuccess -> authControllerProvider becomes authenticated and the
      // router redirects into farm onboarding (Sprint 2). No manual nav here.
    });

    final formState = ref.watch(registerControllerProvider);
    final isSubmitting = formState is FormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  validator: Validators.fullName,
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Email or phone number',
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.emailOrPhone,
                  prefixIcon: Icons.alternate_email,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Confirm password',
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      Validators.confirmPassword(value, _passwordController.text),
                  prefixIcon: Icons.lock_outline,
                  onFieldSubmitted: (_) => _submit(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Text(_obscurePassword ? 'Show password' : 'Hide password'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Create Account',
                  isLoading: isSubmitting,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
