import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AbstractCubit {
  final List<CancelToken> _cancelTokens = [];
  final Set<StreamSubscription> subscriptions = {};

  CancelToken generateCancelToken() {
    final token = CancelToken();
    _cancelTokens.add(token);
    return token;
  }

  @mustCallSuper
  void dispose() {
    _cancelRequests();

    for (var subscription in subscriptions) {
      _cancelSubscriptionSync(subscription);
    }
  }

  void _cancelSubscriptionSync(StreamSubscription subscription) async {
    await subscription.cancel();
  }

  void _cancelRequests() async {
    for (var token in _cancelTokens) {
      try {
        token.cancel();
      } catch (_) {
        // ignore cancel error (AlreadyCancelled, for example)
      }
    }
  }
}
