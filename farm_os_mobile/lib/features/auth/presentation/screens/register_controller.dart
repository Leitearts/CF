import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../auth_providers.dart';

class RegisterController extends StateNotifier<FormSubmissionState> {
  RegisterController(this._ref) : super(const FormIdle());

  final Ref _ref;

  Future<void> submit({
    required String fullName,
    String? email,
    String? phone,
    required String password,
  }) async {
    state = const FormSubmitting();
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );

    result.when(
      success: (user) {
        state = const FormSuccess();
        _ref.read(authControllerProvider.notifier).onAuthenticated(user);
      },
      failure: (failure) => state = FormError(failure),
    );
  }

  void reset() => state = const FormIdle();
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, FormSubmissionState>((ref) {
  return RegisterController(ref);
});
