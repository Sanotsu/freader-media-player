import 'package:shared_preferences/shared_preferences.dart';

import '../utils/game_consts.dart';

class SharedHelper {
  late final SharedPreferences _prefs;

  SharedHelper._create();

  static Future<SharedHelper> init() async {
    var sharedHelper = SharedHelper._create();
    sharedHelper._prefs = await SharedPreferences.getInstance();
    return sharedHelper;
  }

  Future<bool> getHowToPlayShown() async {
    return _prefs.getBool("HowToPlay") ?? false;
  }

  Future<bool> setHowToPlayShown(bool value) async {
    return _prefs.setBool("HowToPlay", value);
  }

  Future<int?> getBestTime(GameMode gameMode) async {
    return _prefs.getInt("${gameMode.name}:BestTime");
  }

  Future<bool> setBestTime(GameMode gameMode, int time) async {
    return _prefs.setInt("${gameMode.name}:BestTime", time);
  }

  Future<int?> getGamesWon(GameMode gameMode) async {
    return _prefs.getInt("${gameMode.name}:GamesWon");
  }

  Future<bool> increaseGamesWon(GameMode gameMode) async {
    int gamesWon = await getGamesWon(gameMode) ?? 0;
    return _prefs.setInt("${gameMode.name}:GamesWon", gamesWon + 1);
  }

  Future<int?> getGamesStarted(GameMode gameMode) async {
    return _prefs.getInt("${gameMode.name}:GamesStarted");
  }

  Future<bool> increaseGamesStarted(GameMode gameMode) async {
    int gamesStarted = await getGamesStarted(gameMode) ?? 0;
    return _prefs.setInt("${gameMode.name}:GamesStarted", gamesStarted + 1);
  }

  Future<int?> getAverageTime(GameMode gameMode) async {
    return _prefs.getInt("${gameMode.name}:AverageTime");
  }

  Future<bool> updateAverageTime(GameMode gameMode, int time) async {
    int? averageTime = await getAverageTime(gameMode);
    int? gamesWon = await getGamesWon(gameMode);

    if (averageTime == null || gamesWon == null) {
      averageTime = time;
    } else {
      var totalTime = gamesWon * averageTime;
      averageTime = ((totalTime + time) / gamesWon + 1).round();
    }
    return _prefs.setInt("${gameMode.name}:AverageTime", averageTime);
  }
}
