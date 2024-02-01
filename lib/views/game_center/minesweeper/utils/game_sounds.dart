enum Sound {
  win,
  lose,
  putFlag,
  removeFlag,
  lastHit,
  clickEmpty,
  clickOne,
  clickTwo,
  clickThree,
  clickFour,
  blue,
  pink,
  purple,
}

extension SoundExtension on Sound {
  String get toPath => 'assets/games/minesweeper/audio/$name.wav';
}

class GameSounds {
  static const Sound _win = Sound.win;
  static const Sound _lose = Sound.lose;
  static const Sound _putFlag = Sound.putFlag;
  static const Sound _removeFlag = Sound.removeFlag;
  static const Sound _lastHit = Sound.lastHit;
  static const Sound _clickEmpty = Sound.clickEmpty;
  static const Sound _clickOne = Sound.clickOne;
  static const Sound _clickTwo = Sound.clickTwo;
  static const Sound _clickThree = Sound.clickThree;
  static const Sound _clickFour = Sound.clickFour;

  static const Sound _blue = Sound.blue;
  static const Sound _pink = Sound.pink;
  static const Sound _purple = Sound.purple;

  static Sound get win => _win;
  static Sound get lose => _lose;
  static Sound get putFlag => _putFlag;
  static Sound get removeFlag => _removeFlag;
  static Sound get lastHit => _lastHit;

  static List<Sound> get clickSounds =>
      [_clickEmpty, _clickOne, _clickTwo, _clickThree, _clickFour];

  static List<Sound> get mineSound => [_purple, _blue, _pink];
}
