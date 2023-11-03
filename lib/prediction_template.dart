import 'package:hunt_stats/db/entities.dart';

class PredictionTemplate {
  final String title;

  final List<String> outcomes;

  final int Function(MatchEntity match) resolver;

  PredictionTemplate(
      {required this.title, required this.outcomes, required this.resolver});

  static final universal = [extracted, deathsOrKills, hasKills];

  static final solo = <PredictionTemplate>[];

  static final duo = [assistsCount, teamKills, killsMoreTeammate];

  static final trio = [assistsCount, teamKills];

  static final killsMoreTeammate = PredictionTemplate(
      title: 'Стрімер вб\'є більше ніж тіммейт?',
      outcomes: ['Так', 'Не так', 'Паритет'],
      resolver: (match) {
        final ownKills = match.match.ownEnemyDowns + match.match.ownEnemyDeaths;
        final teamKills =
            match.match.teamEnemyDeaths + match.match.teamEnemyDowns;
        if (ownKills == teamKills) {
          return 2;
        } else if (ownKills > teamKills) {
          return 0;
        } else {
          return 1;
        }
      });

  static final teamKills = PredictionTemplate(
      title: 'Скільки вбивств зробить команда?',
      outcomes: ['Жодного', '2 або менше', '3 або більше'],
      resolver: (match) {
        final kills = match.match.totalEnemyKillsDowns;
        if (kills == 0) {
          return 0;
        } else if (kills < 3) {
          return 1;
        } else {
          return 2;
        }
      });

  static final assistsCount = PredictionTemplate(
      title: 'Чи будуть ассісти у стрімера?',
      outcomes: [
        'Ні, вони нікого не вб\'ють',
        'Не буде, безкорисний',
        'Стрімер корисний'
      ],
      resolver: (match) {
        if (match.match.ownAssists > 0) {
          return 2;
        } else if (match.match.totalEnemyKillsDowns > 0) {
          return 1;
        } else {
          return 0;
        }
      });

  static final extracted = PredictionTemplate(
      title: 'Вийде стрімер живим з матчу?',
      outcomes: ['Звичайно', 'Не думаю'],
      resolver: (match) {
        return match.match.extracted ? 0 : 1;
      });

  static final deathsOrKills = PredictionTemplate(
      title: 'Вбивств у стрімера буде більше ніж смертей?',
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
