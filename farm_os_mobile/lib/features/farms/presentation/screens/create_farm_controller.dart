import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/form_submission_state.dart';
import '../../farms_providers.dart';
import '../../data/models/create_farm_input.dart';

class CreateFarmController extends StateNotifier<FormSubmissionState> {
  CreateFarmController(this._ref) : super(const FormIdle());

  final Ref _ref;

  Future<void> submit(CreateFarmInput input) async {
    state = const FormSubmitting();
    final repository = _ref.read(farmsRepositoryProvider);
    final result = await repository.createFarm(input);

    await result.when(
      success: (farm) async {
        await _ref.read(farmsControllerProvider.notifier).onFarmCreated(farm);
        state = const FormSuccess();
      },
      failure: (failure) async {
        state = FormError(failure);
      },
    );
  }

  void reset() => state = const FormIdle();
}

final createFarmControllerProvider =
    StateNotifierProvider.autoDispose<CreateFarmController, FormSubmissionState>((ref) {
  return CreateFarmController(ref);
});
