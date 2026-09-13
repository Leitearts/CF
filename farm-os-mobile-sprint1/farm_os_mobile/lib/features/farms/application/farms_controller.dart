import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/result.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/models/farm_input.dart';
import '../data/models/farm_model.dart';
import '../farms_providers.dart';
import 'farms_state.dart';

class FarmsController extends StateNotifier<FarmsState> {
  FarmsController(this._ref) : super(const FarmsState()) {
    loadFarms();
  }

  final Ref _ref;

  Future<void> loadFarms() async {
    state = state.copyWith(isLoading: true, loadFailure: null, saveFailure: null);

    final result = await _ref.read(farmsRepositoryProvider).listFarms();
    switch (result) {
      case Success<List<FarmModel>>(value: final farms):
        final selectedFarm = await _resolveSelectedFarm(farms);
        state = state.copyWith(
          isLoading: false,
          farms: farms,
          selectedFarm: selectedFarm,
          loadFailure: null,
        );
      case Failure<List<FarmModel>>(failure: final failure):
        state = state.copyWith(isLoading: false, loadFailure: failure);
    }
  }

  Future<void> selectFarm(FarmModel farm) async {
    state = state.copyWith(selectedFarm: farm, saveFailure: null);
    await _persistSelectedFarmId(farm.id);

    final result = await _ref.read(farmsRepositoryProvider).getFarm(farm.id);
    switch (result) {
      case Success<FarmModel>(value: final freshFarm):
        final updatedFarms = _replaceFarm(state.farms, freshFarm);
        state = state.copyWith(farms: updatedFarms, selectedFarm: freshFarm, saveFailure: null);
      case Failure<FarmModel>(failure: final failure):
        state = state.copyWith(saveFailure: failure);
    }
  }

  Future<bool> createFarm(CreateFarmInput input) async {
    state = state.copyWith(isSaving: true, saveFailure: null);

    final result = await _ref.read(farmsRepositoryProvider).createFarm(input);
    switch (result) {
      case Success<FarmModel>(value: final farm):
        final updatedFarms = [...state.farms, farm]
          ..sort((first, second) => first.createdAt.compareTo(second.createdAt));
        await _persistSelectedFarmId(farm.id);
        state = state.copyWith(
          isSaving: false,
          farms: updatedFarms,
          selectedFarm: farm,
          saveFailure: null,
        );
        return true;
      case Failure<FarmModel>(failure: final failure):
        state = state.copyWith(isSaving: false, saveFailure: failure);
        return false;
    }
  }

  Future<bool> updateSelectedFarm(UpdateFarmInput input) async {
    final selectedFarm = state.selectedFarm;
    if (selectedFarm == null) return false;

    state = state.copyWith(isSaving: true, saveFailure: null);

    final result = await _ref.read(farmsRepositoryProvider).updateFarm(
          farmId: selectedFarm.id,
          input: input,
        );

    switch (result) {
      case Success<FarmModel>(value: final farm):
        final updatedFarms = _replaceFarm(state.farms, farm);
        state = state.copyWith(
          isSaving: false,
          farms: updatedFarms,
          selectedFarm: farm,
          saveFailure: null,
        );
        return true;
      case Failure<FarmModel>(failure: final failure):
        state = state.copyWith(isSaving: false, saveFailure: failure);
        return false;
    }
  }

  List<FarmModel> _replaceFarm(List<FarmModel> farms, FarmModel replacement) {
    return farms
        .map((farm) => farm.id == replacement.id ? replacement : farm)
        .toList(growable: false);
  }

  Future<FarmModel?> _resolveSelectedFarm(List<FarmModel> farms) async {
    if (farms.isEmpty) {
      await _persistSelectedFarmId(null);
      return null;
    }

    final storage = await _storage();
    final persistedFarmId = storage.activeFarmId;

    final existingSelection = state.selectedFarm;
    if (existingSelection != null) {
      for (final farm in farms) {
        if (farm.id == existingSelection.id) {
          return farm;
        }
      }
    }

    if (persistedFarmId != null) {
      for (final farm in farms) {
        if (farm.id == persistedFarmId) {
          return farm;
        }
      }
    }

    final firstFarm = farms.first;
    await _persistSelectedFarmId(firstFarm.id);
    return firstFarm;
  }

  Future<void> _persistSelectedFarmId(String? farmId) async {
    final storage = await _storage();
    if (farmId == null) {
      await storage.clearActiveFarmId();
      return;
    }
    await storage.setActiveFarmId(farmId);
  }

  Future<LocalStorageService> _storage() {
    return _ref.read(localStorageServiceProvider.future);
  }
}
