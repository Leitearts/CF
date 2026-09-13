import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../auth_providers.dart';

class LoginController extends StateNotifier<FormSubmissionState> {
  LoginController(this._ref) : super(const FormIdle());

  final Ref _ref;

  Future<void> submit({required String identifier, required String password}) async {
    state = const FormSubmitting();
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.login(identifier: identifier, password: password);

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

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, FormSubmissionState>((ref) {
  return LoginController(ref);
});
