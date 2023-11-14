class Prediction {
  final String id;
  final String broadcasterId;
  final String broadcasterName;
  final String broadcasterLogin;
  final String title;
  final String? winningOutcomeId;
  final int predictionWindow;
  final String status;
  final DateTime createdAt;
  final DateTime? lockedAt;
  final DateTime? endedAt;

  final List<Outcome> outcomes;

  Prediction(
      {required this.id,
      required this.broadcasterId,
      required this.broadcasterName,
      required this.broadcasterLogin,
      required this.title,
      required this.winningOutcomeId,
      required this.predictionWindow,
      required this.status,
        required this.outcomes,
      required this.createdAt,
      required this.lockedAt,
      required this.endedAt});

  static Prediction fromJson(dynamic json) {
    return Prediction(
        id: json['id'] as String,
        outcomes: (json['outcomes'] as List<dynamic>).map(Outcome.fromJson).toList(),
        broadcasterId: json['broadcaster_id'] as String,
        broadcasterName: json['broadcaster_name'] as String,
        broadcasterLogin: json['broadcaster_login'] as String,
        title: json['title'] as String,
        winningOutcomeId: json['winning_outcome_id'] as String?,
        predictionWindow: json['prediction_window'] as int,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        lockedAt: _parseOptionalDate(json, 'locked_at'),
        endedAt: _parseOptionalDate(json, 'ended_at'));
  }

  static DateTime? _parseOptionalDate(dynamic json, String name) {
    final value = json[name] as String?;
    return value != null ? DateTime.parse(value).toLocal() : null;
  }
}

class Outcome {
  final String id;
  final String title;
  final int users;
  final int channelPoints;
  final String color;
  final List<Predictor> topPredictors;

  Outcome(
      {required this.id,
      required this.title,
      required this.users,
      required this.channelPoints,
      required this.color,
      required this.topPredictors});

  static Outcome fromJson(dynamic json) {
    return Outcome(
        id: json['id'] as String,
        title: json['title'] as String,
        users: json['users'] as int? ?? 0,
        channelPoints: json['channelPoints'] as int? ?? 0,
        color: json['color'] as String,
        topPredictors: (json['topPredictors'] as List<dynamic>? ?? [])
            .map(Predictor.fromJson)
            .toList());
  }
}

class Predictor {
  final String userId;
  final String userName;
  final String userLogin;
  final int channelPointsUsed;
  final int channelPointsWon;

  Predictor(
      {required this.userId,
      required this.userName,
      required this.userLogin,
      required this.channelPointsUsed,
      required this.channelPointsWon});

  static Predictor fromJson(dynamic json) => Predictor(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userLogin: json['user_login'] as String,
      channelPointsUsed: json['channel_points_used'] as int,
      channelPointsWon: json['channel_points_won'] as int);
}
