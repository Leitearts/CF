import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../auth_providers.dart';

class ForgotPasswordController extends StateNotifier<FormSubmissionState> {
  ForgotPasswordController(this._ref) : super(const FormIdle());

  final Ref _ref;

  Future<void> submit(String identifier) async {
    state = const FormSubmitting();
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.forgotPassword(identifier);
    result.when(
      success: (_) => state = const FormSuccess(),
      failure: (failure) => state = FormError(failure),
    );
  }

  void reset() => state = const FormIdle();
}

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordController, FormSubmissionState>((ref) {
  return ForgotPasswordController(ref);
});

class ResetPasswordController extends StateNotifier<FormSubmissionState> {
  ResetPasswordController(this._ref) : super(const FormIdle());

  final Ref _ref;

  Future<void> submit({
    required String identifier,
    required String resetCode,
    required String newPassword,
  }) async {
    state = const FormSubmitting();
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.resetPassword(
      identifier: identifier,
      resetCode: resetCode,
      newPassword: newPassword,
    );
    result.when(
      success: (_) => state = const FormSuccess(),
      failure: (failure) => state = FormError(failure),
    );
  }

  void reset() => state = const FormIdle();
}

final resetPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ResetPasswordController, FormSubmissionState>((ref) {
  return ResetPasswordController(ref);
});
