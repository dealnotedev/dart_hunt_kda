import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hunt_stats/hunt_bundle.dart';

class TextStatsGenerator {
  final int tableWidth;
  final TableStyle style;

  TextStatsGenerator({required this.tableWidth, required this.style});

  Future<void> write({required HuntBundle bundle, required File file}) {
    final String table = _generateTableContent(bundle);

    if (kDebugMode) {
      print(table);
    }

    return file.writeAsString(_withPadding(table, padding: 1));
  }

  static String _withPadding(String table, {required int padding}) {
    final space = _generateSymbols(padding, ' ');
    return table.split('\n').map((e) => '$space$e$space').join('\n');
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
    return '$start${_generateSymbols(tableWidth - (start.length + end.length), style.horizontalLine)}$end';
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

    String line = '${style.verticalLine} ';
    line += preparedTitle;

    for (int i = 0; i < space; i++) {
      line += ' ';
    }

    line += data;
    line += ' ${style.verticalLine}';
    return line;
  }

  String _generateCenteredText({required String text}) {
    final availableWidth = tableWidth - 2 - 2;

    final actualWidth = text.length;
    final overflow = actualWidth - availableWidth;

    final String preparedText;
    if (overflow > 0) {
      preparedText = text.substring(0, text.length - overflow);
    } else {
      preparedText = text;
    }

    final space = tableWidth - 2 - preparedText.length;
    final spaceLeft = space ~/ 2;
    final spaceRight = space - spaceLeft;

    var line = style.verticalLine;
    line += _generateSymbols(spaceLeft, ' ');
    line += preparedText;
    line += _generateSymbols(spaceRight, ' ');
    line += style.verticalLine;
    return line;
  }

  static String _generateSymbols(int count, String symbol) {
    String text = '';
    for (int i = 0; i < count; i++) {
      text += symbol;
    }
    return text;
  }

  String _generateTableContent(HuntBundle bundle) {
    String table = '';

    table += _generateSimpleLine(
        start: style.halfCrossLeft, end: style.halfCrossRight);
    table += '\n';

    final myKdaChanges = bundle.kdaChanges;
    final myKdaChangesSymbol = myKdaChanges != null && myKdaChanges != 0
        ? (myKdaChanges > 0 ? '△' : '▽')
        : '';

    final myKda =
        '${_formatDouble(bundle.kda)}$myKdaChangesSymbol  ${bundle.totalKills}/${bundle.totalDeaths}';
    table += _generateValuesText(title: 'My K/D', data: myKda);
    table += '\n';

    if (bundle.matches > 0) {
      table += _generateValuesText(
          title: '${_formatMatches(bundle.matches)}, current:',
          data:
              '${bundle.currentMatchKills.valueOrHyphen}/${bundle.currentMatchDeaths.valueOrHyphen}');
    } else {
      table +=
          _generateValuesText(title: _formatMatches(bundle.matches), data: '');
    }

    table += '\n';

    table += _generateSimpleLine(
        start: style.cornerBottomLeft, end: style.cornerBottomRight);

    return table;
  }

  static String _formatMatches(int count) {
    return count == 1 ? '1 game' : '$count games';
  }
}

class TableStyle {
  static const simple = TableStyle(
      horizontalLine: '-',
      verticalLine: '|',
      cornerTopLeft: '◻',
      corentTopRight: '◻',
      halfCrossLeft: '◻',
      halfCrossRight: '◻',
      cornerBottomLeft: '◻',
      cornerBottomRight: '◻');

  static const bold = TableStyle(
      horizontalLine: '━',
      verticalLine: '┃',
      cornerTopLeft: '┏',
      corentTopRight: '┓',
      halfCrossLeft: '┣',
      halfCrossRight: '┨',
      cornerBottomLeft: '┗',
      cornerBottomRight: '┛');

  final String horizontalLine;
  final String verticalLine;

  final String cornerTopLeft;
  final String corentTopRight;

  final String halfCrossLeft;
  final String halfCrossRight;

  final String cornerBottomLeft;
  final String cornerBottomRight;

  const TableStyle(
      {required this.horizontalLine,
      required this.verticalLine,
      required this.cornerTopLeft,
      required this.corentTopRight,
      required this.halfCrossLeft,
      required this.halfCrossRight,
      required this.cornerBottomLeft,
      required this.cornerBottomRight});
}

extension _IntExt on int {
  String get valueOrHyphen => this > 0 ? '$this' : '-';
}

extension _DoubleExt on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}
