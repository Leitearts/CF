import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import 'forgot_password_controller.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.identifier});

  /// Email/phone the reset code was sent to -- passed forward from
  /// ForgotPasswordScreen so the farmer doesn't have to retype it.
  final String identifier;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(resetPasswordControllerProvider.notifier).submit(
          identifier: widget.identifier,
          resetCode: _codeController.text.trim(),
          newPassword: _newPasswordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FormSubmissionState>(resetPasswordControllerProvider, (previous, next) {
      if (next is FormError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.failure.message)),
        );
      }
      if (next is FormSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset. Please log in.')),
        );
        context.go('/login');
      }
    });

    final formState = ref.watch(resetPasswordControllerProvider);
    final isSubmitting = formState is FormSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Enter the code sent to ${widget.identifier} and choose a new password.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  label: 'Reset code',
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, fieldLabel: 'Reset code'),
                  prefixIcon: Icons.pin_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'New password',
                  controller: _newPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.password,
                  prefixIcon: Icons.lock_outline,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: 'Reset Password',
                  isLoading: isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
