enum Mmr {
  star1(count: 1, min: 0, max: 1999),
  star2(count: 2, min: 2000, max: 2299),
  star3(count: 3, min: 2300, max: 2599),
  star4(count: 4, min: 2600, max: 2749),
  star5(count: 5, min: 2750, max: 2999),
  star6(count: 6, min: 3000, max: 5000);

  final int count;
  final int min;
  final int max;

  const Mmr({required this.count, required this.min, required this.max});

  Mmr get previous {
    const all = Mmr.values;

    for (int i = 0; i < all.length; i++) {
      if (count == all[i].count && i > 0) {
        return all[i - 1];
      }
    }

    throw StateError('0 Stars Detected');
  }

  static Mmr get(int mmr) {
    for (var element in Mmr.values) {
      if (element.max < mmr) {
        continue;
      }
      return element;
    }
    throw StateError('Big MMR');
  }

  double getFilled(int mmr) {
    if (mmr >= min) {
      return 1;
    }

    final prev = previous;

    final all = prev.max - prev.min;
    final add = mmr - prev.min;
    return add.toDouble() / all.toDouble();
  }

  static double getNextPart(Mmr current, int mmr) {
    final Mmr? next = Mmr._findNext(current);

    if (next != null) {
      final add = mmr - next.min;
      final all = next.max - next.min;

      return add.toDouble() / all.toDouble();
    } else {
      return 0;
    }
  }

  static Mmr? _findNext(Mmr current) {
    const all = Mmr.values;

    for (int i = 0; i < all.length; i++) {
      if (current.count == all[i].count && i < all.length - 1) {
        return all[i + 1];
      }
    }

    return null;
  }
}
