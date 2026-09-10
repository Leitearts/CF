import '../data/models/farm_model.dart';
import '../../../core/errors/app_failure.dart';

/// Represents "what farms does this user have, and which one is active" --
/// distinct from create/update FORM submission, which reuses the existing
/// FormSubmissionState (see CreateFarmController/EditFarmController), the
/// same pattern already used by Login/Register in Sprint 1. This avoids
/// baking a second "creating/updating" concept into this state on top of
/// the one that already exists.
sealed class FarmsState {
  const FarmsState();
}

class FarmsInitial extends FarmsState {
  const FarmsInitial();
}

class FarmsLoading extends FarmsState {
  const FarmsLoading();
}

class FarmsError extends FarmsState {
  const FarmsError(this.failure);
  final AppFailure failure;
}

class FarmsLoaded extends FarmsState {
  const FarmsLoaded({required this.farms, this.activeFarmId});

  final List<FarmModel> farms;
  final String? activeFarmId;

  bool get hasNoFarms => farms.isEmpty;
  bool get hasMultipleFarms => farms.length > 1;

  FarmModel? get activeFarm {
    if (activeFarmId == null) return null;
    for (final farm in farms) {
      if (farm.id == activeFarmId) return farm;
    }
    return null;
  }

  FarmsLoaded copyWith({
    List<FarmModel>? farms,
    String? activeFarmId,
    bool clearActiveFarmId = false,
  }) {
    return FarmsLoaded(
      farms: farms ?? this.farms,
      activeFarmId: clearActiveFarmId ? null : (activeFarmId ?? this.activeFarmId),
    );
  }
}
