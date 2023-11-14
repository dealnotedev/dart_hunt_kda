class TwitchCreds {
  final String accessToken;

  final String refreshToken;

  final String clientId;

  final String broadcasterId;

  TwitchCreds(
      {required this.accessToken,
      required this.refreshToken,
      required this.broadcasterId,
      required this.clientId});

  TwitchCreds copy(
      {String? accessToken,
      String? refreshToken,
      String? clientId,
      String? broadcasterId}) {
    return TwitchCreds(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        broadcasterId: broadcasterId ?? this.broadcasterId,
        clientId: clientId ?? this.clientId);
  }

  static TwitchCreds fromJson(dynamic json) {
    return TwitchCreds(
        clientId: json['client_id'] as String,
        broadcasterId: json['broadcasterId'] as String,
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'broadcasterId': broadcasterId,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'client_id': clientId
    };
  }
}