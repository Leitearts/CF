import '../../../core/errors/app_failure.dart';
import '../data/models/farm_model.dart';

class FarmsState {
  const FarmsState({
    this.isLoading = true,
    this.isSaving = false,
    this.farms = const [],
    this.selectedFarm,
    this.loadFailure,
    this.saveFailure,
  });

  final bool isLoading;
  final bool isSaving;
  final List<FarmModel> farms;
  final FarmModel? selectedFarm;
  final AppFailure? loadFailure;
  final AppFailure? saveFailure;

  static const Object _sentinel = Object();

  FarmsState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<FarmModel>? farms,
    Object? selectedFarm = _sentinel,
    Object? loadFailure = _sentinel,
    Object? saveFailure = _sentinel,
  }) {
    return FarmsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      farms: farms ?? this.farms,
      selectedFarm: selectedFarm == _sentinel ? this.selectedFarm : selectedFarm as FarmModel?,
      loadFailure: loadFailure == _sentinel ? this.loadFailure : loadFailure as AppFailure?,
      saveFailure: saveFailure == _sentinel ? this.saveFailure : saveFailure as AppFailure?,
    );
  }
}
