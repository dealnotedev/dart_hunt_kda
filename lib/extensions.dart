import 'package:flutter/widgets.dart';
import 'package:hunt_stats/l10n/app_localizations.dart';

extension ContextExt on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this)!;
}
