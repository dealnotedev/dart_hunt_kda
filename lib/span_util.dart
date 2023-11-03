import 'package:flutter/widgets.dart';

class SpanUtil {
  static List<TextSpan> createSpans(String text, String highlighted,
      TextSpan Function(String highlighted) f) {
    final index = text.indexOf(highlighted);

    if (index != -1) {
      return [
        if (index > 0) ...{TextSpan(text: text.substring(0, index))},
        f.call(highlighted),
        if (index < text.length) ...{
          TextSpan(text: text.substring(index + highlighted.length))
        }
      ];
    } else {
      return [TextSpan(text: text)];
    }
  }

  static List<TextSpan> createSpansAdvanced(String text,
      List<String> highlighted, TextSpan Function(String highlighted) f) {
    final entries = _parseText(text, highlighted);
    final spans = <TextSpan>[];

    for (var entry in entries) {
      if (entry.highlighted) {
        spans.add(f.call(entry.part));
      } else {
        spans.add(TextSpan(text: entry.part));
      }
    }

    return spans;
  }

  static List<_Entry> _parseText(String text, List<String> highlighted) {
    final entries = <_Entry>[];

    for (var part in highlighted) {
      final int index = text.indexOf(part);
      if (index != -1) {
        final entry = _Entry(
            from: index,
            to: index + part.length,
            part: part,
            highlighted: true);
        entries.add(entry);
      }
    }

    entries.sort((a, b) => a.from.compareTo(b.from));

    final result = <_Entry>[];

    int offset = 0;
    for (var entry in entries) {
      if (entry.from > offset) {
        result.add(_Entry(
            from: offset,
            to: entry.from,
            part: text.substring(offset, entry.from),
            highlighted: false));
      }
      result.add(entry);
      offset = entry.to;
    }

    if (offset < text.length) {
      result.add(_Entry(
          from: offset,
          to: text.length,
          part: text.substring(offset),
          highlighted: false));
    }

    return result;
  }
}

class _Entry {
  final int from;
  final int to;
  final String part;
  final bool highlighted;

  _Entry(
      {required this.from,
      required this.to,
      required this.part,
      required this.highlighted});

  @override
  String toString() => '[[$from - $to]$part]';
}

class _Part {
  final String? text;
  final String? icon;

  _Part(this.text, this.icon);

  @override
  String toString() {
    return (text ?? '') + (icon ?? '');
  }
}

class IconId {
  final int start;
  final int end;
  final String id;

  IconId(this.start, this.end, this.id);
}
