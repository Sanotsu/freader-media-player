enum GameMode { easy, medium, hard }

int getBoardLength(GameMode gameMode) {
  if (gameMode.name == 'easy') {
    return 10;
  } else if (gameMode.name == 'medium') {
    return 25;
  }
  return 48;
}

int mineCount(GameMode gameMode) {
  if (gameMode.name == 'easy') {
    return 15;
  } else if (gameMode.name == 'medium') {
    return 40;
  }
  return 99;
}
