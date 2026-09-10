import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/farm_model.dart';
import '../data/repositories/farms_repository.dart';
import '../../../core/storage/local_storage_service.dart';
import 'farms_state.dart';

/// Owns "which farms does this user have, and which one is active".
///
/// Reconciliation algorithm on load (Sprint 2 section 11 -- the backend
/// remains authoritative, a locally stored activeFarmId is never trusted
/// blindly):
///   1. fetch the user's farms from the backend
///   2. read the locally stored activeFarmId
///   3. if it matches one of the returned farms, keep it
///   4. if it doesn't match any (farm deleted / access revoked / stale
///      device data), clear it locally
///   5. if the farmer has exactly one farm and nothing is currently active,
///      auto-select it -- asking a farmer with a single farm to "select"
///      it would be pure friction (this is a judgment call beyond what the
///      brief specified explicitly; flagged in the Sprint 2 report)
class FarmsController extends StateNotifier<FarmsState> {
  FarmsController({
    required FarmsRepository repository,
    required LocalStorageService localStorage,
  })  : _repository = repository,
        _localStorage = localStorage,
        super(const FarmsInitial());

  final FarmsRepository _repository;
  final LocalStorageService _localStorage;

  Future<void> loadFarms() async {
    state = const FarmsLoading();
    final result = await _repository.getFarms();

    await result.when(
      success: (farms) async {
        final storedActiveFarmId = _localStorage.activeFarmId;
        String? resolvedActiveFarmId;

        final storedIdIsValid =
            storedActiveFarmId != null && farms.any((f) => f.id == storedActiveFarmId);

        if (storedIdIsValid) {
          resolvedActiveFarmId = storedActiveFarmId;
        } else if (storedActiveFarmId != null) {
          // Stored id no longer corresponds to an accessible farm -- clear it
          // rather than silently pretending it's still valid.
          await _localStorage.clearActiveFarmId();
        }

        if (resolvedActiveFarmId == null && farms.length == 1) {
          resolvedActiveFarmId = farms.first.id;
          await _localStorage.setActiveFarmId(resolvedActiveFarmId);
        }

        state = FarmsLoaded(farms: farms, activeFarmId: resolvedActiveFarmId);
      },
      failure: (failure) async {
        state = FarmsError(failure);
      },
    );
  }

  Future<void> selectFarm(String farmId) async {
    final current = state;
    if (current is! FarmsLoaded) return;
    if (!current.farms.any((f) => f.id == farmId)) {
      // Defensive: never trust a farm id the UI didn't get from this
      // controller's own farms list (section 23: "do not trust a farm ID
      // supplied only by the UI").
      return;
    }
    await _localStorage.setActiveFarmId(farmId);
    state = current.copyWith(activeFarmId: farmId);
  }

  void clearActiveFarm() {
    final current = state;
    if (current is! FarmsLoaded) return;
    _localStorage.clearActiveFarmId();
    state = current.copyWith(clearActiveFarmId: true);
  }

  /// Called by CreateFarmController on a successful POST /farms -- the new
  /// farm becomes active immediately (matches onboarding acceptance test:
  /// "Farm becomes the active farm").
  Future<void> onFarmCreated(FarmModel farm) async {
    final current = state;
    final existingFarms = current is FarmsLoaded ? current.farms : <FarmModel>[];
    await _localStorage.setActiveFarmId(farm.id);
    state = FarmsLoaded(farms: [...existingFarms, farm], activeFarmId: farm.id);
  }

  /// Called by EditFarmController on a successful PUT /farms/:id.
  void onFarmUpdated(FarmModel updatedFarm) {
    final current = state;
    if (current is! FarmsLoaded) return;
    final updatedList = [
      for (final farm in current.farms)
        if (farm.id == updatedFarm.id) updatedFarm else farm,
    ];
    state = current.copyWith(farms: updatedList);
  }
}
