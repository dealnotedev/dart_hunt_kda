import 'package:hunt_stats/db/entities.dart';

class PredictionTemplate {
  final String title;

  final List<String> outcomes;

  final int Function(MatchEntity match) resolver;

  PredictionTemplate(
      {required this.title, required this.outcomes, required this.resolver});

  static final universal = [
    extracted,
    deathsOrKills,
    hasKills
  ];

  static final extracted = PredictionTemplate(
      title: 'Вийде стрімер живим з матчу?',
      outcomes: ['Звичайно', 'Не думаю'],
      resolver: (match) {
        return match.match.extracted ? 0 : 1;
      });

  static final deathsOrKills = PredictionTemplate(
      title: 'Вбивств буде більше ніж смертей?',
      outcomes: ['Вбивств більше', 'Однаково', 'Смертей більше'],
      resolver: (match) {
        final kills = match.match.ownEnemyDeaths + match.match.ownEnemyDowns;
        final deaths = match.match.ownDeaths + match.match.ownDowns;
        if (kills == deaths) {
          return 1;
        } else if (kills > deaths) {
          return 0;
        } else {
          return 2;
        }
      });

  static final hasKills = PredictionTemplate(
      title: 'Стрімер когось вб\'є?',
      outcomes: ['Без кілів', 'Одного', 'Більше'],
      resolver: (match) {
        final kills = match.match.ownEnemyDeaths + match.match.ownEnemyDowns;
        switch (kills) {
          case 0:
            return 0;
          case 1:
            return 1;
          default:
            return 2;
        }
      });
}
