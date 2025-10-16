import 'dart:async';

import 'package:rxdart/rxdart.dart';

class ObservableValue<T> {
  T current;

  final _subject = StreamController<T>.broadcast();

  ObservableValue({required this.current});

  Stream<T> get value => Stream.value(current).concatWith([_subject.stream]);

  T set(T value) {
    current = value;
    _subject.add(value);
    return value;
  }

  Future<T> get firstNonNull =>
      current != null ? Future.value(current) : _subject.stream.first;

  void notifyUpdates() {
    _subject.add(current);
  }

  void apply(void Function(T current) fn) {
    fn(current);
    _subject.add(current);
  }

  void apply2(bool Function(T current) fn) {
    if (fn(current)) {
      _subject.add(current);
    }
  }

  Stream<T> get changes => _subject.stream;

  void release() {
    _subject.close();
  }
}
