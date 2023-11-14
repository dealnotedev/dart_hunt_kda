import 'dart:async';

import 'package:rxdart/rxdart.dart';

class ObservableValue<T> {
  T current;

  final _subject = StreamController<T>.broadcast();

  ObservableValue({required this.current});

  Stream<T> get value => Stream.value(current).concatWith([_subject.stream]);

  DateTime _lastTime = DateTime.now();

  void set(T value) {
    if (current != value) {
      current = value;
      _lastTime = DateTime.now();
      _subject.add(value);
    }
  }

  void update(T Function(T current) updater) {
    set(updater.call(current));
  }

  void notifyUpdates() {
    _subject.add(current);
  }

  Duration get outdated => DateTime.now().difference(_lastTime);

  bool isOlder(Duration duration, {bool invalidateLastTime = false}) {
    final now = DateTime.now();
    final result = now.difference(_lastTime).compareTo(duration) > 0;

    if (result && invalidateLastTime) {
      _lastTime = now;
    }

    return result;
  }

  Stream<T> get changes => _subject.stream;

  void dispose() {
    _subject.close();
  }
}
