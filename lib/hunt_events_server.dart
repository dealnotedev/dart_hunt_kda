import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A single loopback publisher for any number of OBS source clients.
class HuntEventsServer {
  final int requestedPort;
  final _clients = <WebSocket>{};
  HttpServer? _server;
  Future<void>? _starting;
  Future<void>? _closing;
  bool _closed = false;

  HuntEventsServer({this.requestedPort = 4080});

  int? get port => _server?.port;

  Future<void> start() => _starting ??= _start();

  Future<void> _start() async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      requestedPort,
    );
    if (_closed) {
      await server.close(force: true);
      return;
    }
    _server = server;
    server.listen((request) => unawaited(_handle(request)));
  }

  Future<void> _handle(HttpRequest request) async {
    if (request.uri.path != '/v1/events' ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      if (_closed) {
        await socket.close(WebSocketStatus.goingAway);
        return;
      }
      _clients.add(socket);
      socket.listen(
        (_) {},
        onDone: () => _clients.remove(socket),
        onError: (Object _) {
          _clients.remove(socket);
          unawaited(socket.close());
        },
        cancelOnError: true,
      );
      socket.add(jsonEncode({'version': 1, 'type': 'ready'}));
    } on WebSocketException {
      // A client may disconnect during the upgrade.
    } on SocketException {
      // Client lifetimes never interrupt game tracking.
    }
  }

  void publishKill({
    required String text,
    required int inMatch,
    required int inMatchStreak,
    required int totalStreak,
  }) {
    if (_closed || _clients.isEmpty) return;
    final payload = jsonEncode({
      'version': 1,
      'type': 'kill',
      'text': text,
      'in_match': inMatch,
      'in_match_streak': inMatchStreak,
      'total_streak': totalStreak,
    });
    for (final socket in _clients.toList()) {
      try {
        socket.add(payload);
      } on StateError {
        _clients.remove(socket);
      } on WebSocketException {
        _clients.remove(socket);
      }
    }
  }

  Future<void> close() => _closing ??= () async {
    _closed = true;
    try {
      await _starting;
    } on SocketException {
      // No listener was created if the configured port was occupied.
    }
    await _server?.close(force: true);
    _server = null;
    await Future.wait([
      for (final socket in _clients.toList())
        socket.close(WebSocketStatus.goingAway),
    ]);
    _clients.clear();
  }();
}
