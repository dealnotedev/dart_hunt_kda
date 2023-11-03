import 'package:hunt_stats/nullable.dart';
import 'package:hunt_stats/tracker.dart';
import 'package:hunt_stats/twitch/twitch_panel_cubit.dart';

class TwitchPanelState {
  final MissionState missionState;

  final PredictionPair? active;

  final bool processing;

  TwitchPanelState(
      {required this.missionState,
      required this.active,
      required this.processing});

  TwitchPanelState copy(
      {MissionState? missionState,
      Nullable<PredictionPair?>? active,
      bool? processing}) {
    return TwitchPanelState(
        processing: processing ?? this.processing,
        missionState: missionState ?? this.missionState,
        active: active.getOr(this.active));
  }
}
