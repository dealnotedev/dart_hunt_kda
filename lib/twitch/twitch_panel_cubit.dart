import 'package:hunt_stats/abstract_cubit.dart';
import 'package:hunt_stats/db/entities.dart';
import 'package:hunt_stats/extensions.dart';
import 'package:hunt_stats/nullable.dart';
import 'package:hunt_stats/observable_value.dart';
import 'package:hunt_stats/prediction_template.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:hunt_stats/twitch/prediction.dart';
import 'package:hunt_stats/twitch/settings.dart';
import 'package:hunt_stats/twitch/twitch_api.dart';
import 'package:hunt_stats/twitch/twitch_panel_state.dart';

class TwitchPanelCubit extends AbstractCubit {
  final TrackerEngine engine;
  final TwitchApi twitchApi;
  final Settings settings;

  TwitchPanelCubit(
      {required this.engine, required this.twitchApi, required this.settings})
      : state = ObservableValue(
            current: TwitchPanelState(
                missionState: engine.lastKnownMissionState,
                active: null,
                processing: false)) {
    subscriptions.add(engine.missionState.listen(_handleMissionState));
    subscriptions.add(engine.newMatches.listen(_handleNewMatchFound));
    _cancelActivePredictions();
  }

  final ObservableValue<TwitchPanelState> state;

  String? get broadcasterId => settings.twitchAuth?.broadcasterId;

  Future<void> _cancelActivePredictions() async {
    final response = await twitchApi.getPredictions(
        broadcasterId: broadcasterId, count: 1, after: null);

    for (var prediction in response) {
      if (Statuses.locked == prediction.status ||
          Statuses.active == prediction.status) {
        await twitchApi.endPrediction(
            broadcasterId: broadcasterId,
            id: prediction.id,
            status: Statuses.canceled,
            winningOutcomeId: null);
      }
    }
  }

  bool _automatically = false;

  Future<void> runPrediction(
      {required bool automatically,
      required List<PredictionTemplate> available}) async {
    _automatically = automatically;
    _available = available;

    if (_activePrediction != null) {
      return;
    }

    await _runPredictionInternal();
  }

  List<PredictionTemplate> _available = PredictionTemplate.universal;

  Future<void> _runPredictionInternal() async {
    final template = _available.random;

    try {
      state.set(state.current.copy(processing: true));

      final created = await _createByTemplate(template);

      state.set(state.current.copy(
          processing: false,
          active: Nullable(
              PredictionPair(template: template, prediction: created))));
    } catch (_) {
      state.set(state.current.copy(processing: false));
    }
  }

  PredictionPair? get _activePrediction => state.current.active;

  Future<Prediction> _createByTemplate(PredictionTemplate template) {
    return twitchApi.createPrediction(
        broadcasterId: broadcasterId,
        title: template.title,
        outcomes: template.outcomes,
        predictionWindow: 300);
  }

  void _handleMissionState(MissionState event) async {
    state.set(state.current.copy(missionState: event));

    switch (event) {
      case MissionState.empty:
      case MissionState.ended:
      case MissionState.unknown:
        break;

      case MissionState.started:
        await _lockActivePrediction();
        break;
    }
  }

  Future<void> _lockActivePrediction() async {
    final active = _activePrediction;
    if (active != null) {
      await twitchApi.endPrediction(
          broadcasterId: broadcasterId,
          id: active.prediction.id,
          status: 'LOCKED',
          winningOutcomeId: null);
    }
  }

  void _handleNewMatchFound(MatchEntity match) async {
    final active = _activePrediction;

    if (active != null) {
      final winner = active.template.resolver.call(match);
      final winnerId = active.prediction.outcomes[winner].id;

      state.set(state.current.copy(processing: true));

      try {
        await twitchApi.endPrediction(
            broadcasterId: broadcasterId,
            id: active.prediction.id,
            status: Statuses.resolved,
            winningOutcomeId: winnerId);
        state
            .set(state.current.copy(processing: false, active: Nullable(null)));

        if (_automatically) {
          await Future.delayed(const Duration(seconds: 10));
          await _runPredictionInternal();
        }
      } catch (_) {
        state.set(state.current.copy(processing: false));
      }
    }
  }

  Future<void> stop() async {
    final active = _activePrediction;
    if (active != null) {
      state.set(state.current.copy(processing: true));

      try {
        await twitchApi.endPrediction(
            broadcasterId: broadcasterId,
            id: active.prediction.id,
            status: Statuses.canceled,
            winningOutcomeId: null);
        state
            .set(state.current.copy(active: Nullable(null), processing: false));
      } catch (_) {
        state.set(state.current.copy(processing: false));
      }
    }
  }
}

class PredictionPair {
  final PredictionTemplate template;
  final Prediction prediction;

  PredictionPair({required this.template, required this.prediction});
}
