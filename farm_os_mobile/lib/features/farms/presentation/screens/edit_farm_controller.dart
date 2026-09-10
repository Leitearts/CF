import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../farms_providers.dart';
import '../../data/models/update_farm_input.dart';

class EditFarmController extends StateNotifier<FormSubmissionState> {
  EditFarmController(this._ref) : super(const FormIdle());

  final Ref _ref;

  Future<void> submit(String farmId, UpdateFarmInput input) async {
    state = const FormSubmitting();
    final repository = _ref.read(farmsRepositoryProvider);
    final result = await repository.updateFarm(farmId, input);

    result.when(
      success: (farm) {
        _ref.read(farmsControllerProvider.notifier).onFarmUpdated(farm);
        state = const FormSuccess();
      },
      failure: (failure) => state = FormError(failure),
    );
  }

  void reset() => state = const FormIdle();
}

final editFarmControllerProvider =
    StateNotifierProvider.autoDispose<EditFarmController, FormSubmissionState>((ref) {
  return EditFarmController(ref);
});
