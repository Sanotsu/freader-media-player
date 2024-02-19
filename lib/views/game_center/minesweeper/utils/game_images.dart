enum Images {
  stopwatch,
  trophy,
  flag,
  redCross,
  loseScreen,
  winScreen,
  homeScreenBg,
  pickaxe,
}

extension ImagesExtension on Images {
  String get toPath => 'assets/games/minesweeper/images/$name.png';
}
