import '../helper/shared_helper.dart';
import '../utils/game_consts.dart';

mixin StatisticsMixin {
  String timeFormatter(int? time) {
    if (time == null) {
      return "--:--";
    }
    Duration duration = Duration(seconds: time);
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds - minutes * 60;
    return "${(minutes > 9 ? "" : "0")}$minutes:${(seconds > 9 ? "" : "0")}$seconds";
  }

  Future<Map<String, dynamic>> getStatistic(GameMode gameMode) async {
    final SharedHelper sharedHelper = await SharedHelper.init();

    int? gamesStarted = await sharedHelper.getGamesStarted(gameMode);
    int? gamesWon = await sharedHelper.getGamesWon(gameMode);
    int? bestTime = await sharedHelper.getBestTime(gameMode);
    int? averageTime = await sharedHelper.getAverageTime(gameMode);

    String? winRate;

    if (gamesStarted != null) {
      if (gamesWon != null) {
        winRate = "${(gamesWon * 100 / gamesStarted).round()}%";
      } else {
        winRate = "0%";
      }
    }

    return {
      "gamesStarted": gamesStarted,
      "gamesWon": gamesWon,
      "winRate": winRate,
      "bestTime": timeFormatter(bestTime),
      "averageTime": timeFormatter(averageTime),
    };
  }
}
