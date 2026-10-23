import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hunt_stats/hunt_events_server.dart';

void main() {
  test('one listener broadcasts each live kill to every source', () async {
    final server = HuntEventsServer(requestedPort: 0);
    await server.start();
    final sockets = <WebSocket>[];
    addTearDown(() async {
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });
    final events = <StreamIterator<dynamic>>[];
    for (var i = 0; i < 2; i++) {
      final socket = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/v1/events',
      );
      sockets.add(socket);
      final iterator = StreamIterator<dynamic>(socket);
      events.add(iterator);
      expect(await iterator.moveNext(), isTrue);
      expect(jsonDecode(iterator.current as String), {
        'version': 1,
        'type': 'ready',
      });
    }
    server.publishKill(
      text: 'Double Kill',
      inMatch: 2,
      inMatchStreak: 2,
      totalStreak: 4,
    );
    for (final iterator in events) {
      expect(await iterator.moveNext(), isTrue);
      expect(jsonDecode(iterator.current as String), {
        'version': 1,
        'type': 'kill',
        'text': 'Double Kill',
        'in_match': 2,
        'in_match_streak': 2,
        'total_streak': 4,
      });
    }
  });

  test(
    'tracking without clients does not queue old kills for a new source',
    () async {
      final server = HuntEventsServer(requestedPort: 0);
      await server.start();
      server.publishKill(
        text: 'old',
        inMatch: 1,
        inMatchStreak: 1,
        totalStreak: 1,
      );
      final socket = await WebSocket.connect(
        'ws://127.0.0.1:${server.port}/v1/events',
      );
      final events = StreamIterator<dynamic>(socket);
      addTearDown(() async {
        await socket.close();
        await server.close();
      });
      await events.moveNext();
      server.publishKill(
        text: 'new',
        inMatch: 2,
        inMatchStreak: 2,
        totalStreak: 2,
      );
      await events.moveNext();
      expect(jsonDecode(events.current as String)['text'], 'new');
    },
  );

  test('closing the publisher releases its port', () async {
    final server = HuntEventsServer(requestedPort: 0);
    await server.start();
    final port = server.port!;
    await server.close();
    await server.close();
    final replacement = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );
    await replacement.close(force: true);
  });
}
