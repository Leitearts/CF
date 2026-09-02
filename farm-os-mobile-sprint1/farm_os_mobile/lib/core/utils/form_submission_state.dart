import '../../../../core/errors/app_failure.dart';

/// Generic "submitting a form" state, reused by every auth form controller
/// (and, in later sprints, every other write-action controller) so the UI
/// pattern is identical everywhere: idle -> submitting -> success/failure.
sealed class FormSubmissionState {
  const FormSubmissionState();
}

class FormIdle extends FormSubmissionState {
  const FormIdle();
}

class FormSubmitting extends FormSubmissionState {
  const FormSubmitting();
}

class FormSuccess extends FormSubmissionState {
  const FormSuccess();
}

class FormError extends FormSubmissionState {
  const FormError(this.failure);
  final AppFailure failure;
}
