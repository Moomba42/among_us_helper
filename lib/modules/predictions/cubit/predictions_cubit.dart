import "dart:async";

import "package:among_us_helper/core/model/player.dart";
import "package:among_us_helper/modules/predictions/model/predictions.dart";
import "package:among_us_helper/modules/predictions/repositories/predictions_repository.dart";
import "package:bloc/bloc.dart";
import "package:logging/logging.dart";
import "package:meta/meta.dart";

part "predictions_state.dart";

class PredictionsCubit extends Cubit<PredictionsState> {
  final Logger _logger = Logger("PredictionsCubit");
  final PredictionsRepository _predictionsRepository;

  StreamSubscription<Map<PredictionsSection, List<Player>>> _predictionsSubscription;

  PredictionsCubit({@required PredictionsRepository predictionsRepository})
      : this._predictionsRepository = predictionsRepository,
        super(PredictionsInitial()) {
    _predictionsSubscription = _predictionsRepository.predictionsMap().listen(
        (Map<PredictionsSection, List<Player>> event) => this.emit(PredictionsLoadSuccess(event)));
  }

  /// Moves a player to a given section to the given position.
  /// Also makes sure that the player is not present in other sections.
  void move({@required Player player, @required PredictionsSection section, int newPosition = 0}) {
    if (state is PredictionsLoadSuccess) {
      PredictionsLoadSuccess successState = state;

      // Copy the original predictions
      Map<PredictionsSection, List<Player>> newPredictions =
          _duplicateMappedLists(successState.predictions);

      // Move the player to the desired section
      newPredictions.forEach((key, value) => value.remove(player));
      newPredictions[section].insert(newPosition, player);

      // Push changes to the repository to update the UI
      _predictionsRepository.update(newPredictions);
    } else {
      _logger.warning("No predictions data. Could not modify state.");
    }
  }

  /// Pushes a new state that has all players in the unknown section.
  void reset() {
    // Create a list for each section
    List<MapEntry<PredictionsSection, List<Player>>> defaultEntries = PredictionsSection.values
        .map((e) => MapEntry(e, List<Player>.empty(growable: true)))
        .toList();

    // Convert the list to a map
    Map<PredictionsSection, List<Player>> defaultMapState = Map.fromEntries(defaultEntries);

    // Add all players to the unknown section
    defaultMapState[PredictionsSection.UNKNOWN].addAll(Player.values);

    // Push changes to the repository to update the UI
    _predictionsRepository.update(defaultMapState);
  }

  @override
  Future<Function> close() {
    _predictionsSubscription?.cancel();
    return super.close();
  }

  /// Helper method which deep-duplicates the given mapped lists.
  /// Use this when you want to make sure updates to the lists
  /// in the new map won"t affect the original ones.
  Map<K, List<T>> _duplicateMappedLists<K, T>(Map<K, List<T>> map) {
    return map.map((key, value) => MapEntry(key, List.of(value)));
  }
}