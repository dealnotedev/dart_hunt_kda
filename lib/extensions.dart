import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension ContextExt on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this)!;
}

extension ListExt<T> on List<T> {
  List<T> trimToLength(int size) {
    return sublist(0, min(length, size));
  }

  T get random {
    return this[Random().nextInt(length)];
  }
}