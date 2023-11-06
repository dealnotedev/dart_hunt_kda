import 'dart:io';

import 'package:hunt_stats/hunt_bundle.dart';
import 'package:hunt_stats/mmr.dart';

class TextStatsGenerator {
  final int tableWidth;

  TextStatsGenerator({required this.tableWidth});

  Future<void> write({required HuntBundle bundle, required File file}) {
    final table = _generateTableContent(bundle);
    return file.writeAsString(table);
  }

  static String _formatDouble(double value,
      {int precision = 2, bool plusIfPositive = false}) {
    if (value.isNaN) {
      return '';
    }
    if (value.isInfinite) {
      return value.isNegative ? '-∞' : '∞';
    }
    final formatted = value.toPrecision(precision).toString();
    return plusIfPositive && value > 0 ? '+$formatted' : formatted;
  }

  String _generateSimpleLine({required String start, required String end}) {
    String line = '';
    for (int i = 0; i < tableWidth; i++) {
      if (i == 0) {
        line += start;
      } else if (i == tableWidth - 1) {
        line += end;
      } else {
        line += '-';
      }
    }
    return line;
  }

  String _generateValuesText({required String title, required String data}) {
    final availableWidth = tableWidth - 2 - 2;

    final actualWidth = title.length + data.length + 1;
    final overflow = actualWidth - availableWidth;

    final String preparedTitle;
    if (overflow > 0) {
      preparedTitle = title.substring(0, title.length - overflow);
    } else {
      preparedTitle = title;
    }

    final space = tableWidth - 2 - preparedTitle.length - 2 - data.length;

    String line = '| ';
    line += preparedTitle;

    for (int i = 0; i < space; i++) {
      line += ' ';
    }

    line += data;
    line += ' |';
    return line;
  }

  String _generatePlayerText({required String name, required String data}) {
    final availableWidth = tableWidth - 2 - 2;

    final actualWidth = name.length + data.length + 1;
    final overflow = actualWidth - availableWidth;

    final String preparedName;
    if (overflow > 0) {
      preparedName = name.substring(0, name.length - overflow);
    } else {
      preparedName = name;
    }

    final space = tableWidth - 2 - preparedName.length - 1 - data.length;
    final spaceLeft = space ~/ 2;
    final spaceRight = space - spaceLeft;

    String line = '|';
    for (int i = 0; i < spaceLeft; i++) {
      line += ' ';
    }
    line += preparedName;
    line += ' ';
    line += data;
    for (int i = 0; i < spaceRight; i++) {
      line += ' ';
    }

    line += '|';
    return line;
  }

  static String _generateStars(int count) {
    String text = '';
    for (int i = 0; i < count; i++) {
      text += '*';
    }
    return text;
  }

  String _generateTableContent(HuntBundle bundle) {
    String table = '';
    table += _generateSimpleLine(start: '◸', end: '◹');
    table += '\n';

    for (var player in bundle.match.players) {
      if (!player.teammate) continue;

      final mmr = Mmr.get(player.mmr);
      final fill = Mmr.findNext(mmr)?.getFilled(player.mmr);

      final stars = mmr.count + (fill ?? 0.0);
      final data =
          '${_generateStars(mmr.count)} ${stars.toStringAsPrecision(2)}';
      table += _generatePlayerText(name: player.username, data: data);
      table += '\n';
    }

    table += _generateSimpleLine(start: '◻', end: '◻');
    table += '\n';

    final myKdaChanges = bundle.kdaChanges;
    final myKdaChangesSymbol = myKdaChanges != null && myKdaChanges != 0
        ? (myKdaChanges > 0 ? '△' : '▽')
        : '';

    final myKda =
        '${_formatDouble(bundle.ownStats.kda)}$myKdaChangesSymbol ${bundle.ownStats.ownKills}/${bundle.ownStats.ownDeaths}/${bundle.ownStats.ownAssists}';
    table += _generateValuesText(title: 'My KDA', data: myKda);
    table += '\n';

    final teamKdChanges = bundle.teamKdChanges;
    final teamKdChangesSymbol = teamKdChanges != null && teamKdChanges != 0
        ? (teamKdChanges > 0 ? '△' : '▽')
        : '';

    final teamKd =
        '${_formatDouble(bundle.teamStats.kd)}$teamKdChangesSymbol ${bundle.teamStats.teamKills}/${bundle.teamStats.teamDeaths}';
    table += _generateValuesText(title: 'Team KD', data: teamKd);
    table += '\n';
    table += _generateSimpleLine(start: '◺', end: '◿');

    return table;
  }
}

extension _DoubleExt on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}
