import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../helper/audio_player.dart';
import '../helper/shared_helper.dart';
import '../model/tile_model.dart';
import '../utils/game_consts.dart';
import '../utils/game_sounds.dart';
import '../view/home_view/home_view.dart';
import '../widgets/game_popup_screen.dart';

class GameController extends ChangeNotifier {
  late GameAudioPlayer _audioPlayer;
  SharedHelper? _sharedHelper;

  GameController() {
    _audioPlayer = GameAudioPlayer();
    _createGameBoard();
  }

  /// The game board matrix / minefield
  final List<List<Tile>> _mineField = [];
  List<List<Tile>> get mineField => _mineField;

  int _boardLength = 10;
  int get boardLength => _boardLength;

  int _flagCount = 15;
  int get flagCount => _flagCount;

  int _mineCount = 15;
  int _openedTileCount = 0;

  int _timeElapsed = 0;
  int get timeElapsed => _timeElapsed;

  bool _gameHasStarted = false;
  bool get gameHasStarted => _gameHasStarted;
  bool _gameOver = false;
  bool _minesAnimation = false;

  bool get isMineAnimationOn => _minesAnimation;

  set minesAnimation(bool value) {
    _minesAnimation = value;
    notifyListeners();
  }

  bool _volumeOn = true;

  /// Volume setting (on/off)
  bool get volumeOn => _volumeOn;

  /// Volume setting setter
  set changeVolumeSetting(bool value) {
    _volumeOn = value;
    GameAudioPlayer.setVolume(_volumeOn);
    notifyListeners();
  }

  /// Game difficulty setting.
  /// This setting determines the matrix size and number of mines
  GameMode _gameMode = GameMode.easy;
  GameMode get gameMode => _gameMode;

  /// Game mode setter
  set gameMode(GameMode mode) {
    _gameMode = mode;
    _boardLength = getBoardLength(_gameMode);
    _mineCount = mineCount(_gameMode);
    resetGame();
    createNewGame();
  }

  /// Starts the timer
  void _startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_gameHasStarted || _gameOver || _timeElapsed >= 999) {
        timer.cancel();
        return;
      }
      _timeElapsed++;
      notifyListeners();
    });
  }

  List<Tile> findMines() {
    List<Tile> mines = [];

    for (List<Tile> row in mineField) {
      for (Tile tile in row) {
        if (!tile.visible && tile.hasMine && !tile.hasFlag) {
          mines.add(tile);
        }
      }
    }

    return mines;
  }

  List<Tile> findMissPlacesFlags() {
    List<Tile> missPlacesFlags = [];

    for (List<Tile> row in mineField) {
      for (Tile tile in row) {
        if (!tile.visible && !tile.hasMine && tile.hasFlag) {
          missPlacesFlags.add(tile);
        }
      }
    }

    return missPlacesFlags;
  }

  /// Makes all mines visible
  Future<void> showAllMines() async {
    List<Tile> mines = findMines();
    mines.shuffle();

    await Future.delayed(const Duration(milliseconds: 300));

    _minesAnimation = true;

    var rnd = Random();

    for (var mine in mines) {
      int r = mine.row;
      int c = mine.col;

      mineField[r][c].setVisible = true;
      if (_minesAnimation) {
        notifyListeners();
        await _audioPlayer.playAudio(GameSounds.mineSound[rnd.nextInt(3)]);
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    notifyListeners();

    await showMissPlacesFlags();

    _minesAnimation = false;
  }

  Future<void> showMissPlacesFlags() async {
    if (_minesAnimation) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    List<Tile> missPlacesFlags = findMissPlacesFlags();
    for (var mine in missPlacesFlags) {
      int r = mine.row;
      int c = mine.col;

      mineField[r][c].setVisible = true;
      notifyListeners();
    }
    if (missPlacesFlags.isNotEmpty && _minesAnimation) {
      await _audioPlayer.playAudio(GameSounds.removeFlag);
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  /// Creates empty board
  void _createGameBoard() {
    for (var i = 0; i < _boardLength; i++) {
      _mineField.add([]);
      for (var j = 0; j < 10; j++) {
        _mineField[i].add(Tile(i, j));
      }
    }
  }

  /// Creates a new game
  void createNewGame() {
    resetGame();
    _createGameBoard();
    notifyListeners();
  }

  /// Game start function
  void startGame(Tile tile) {
    _gameHasStarted = true;
    _addGameStartLog();
    _startTimer();
    _placeMines(tile);
    _openTile(tile.row, tile.col, playSound: true);
  }

  Future<void> _addGameStartLog() async {
    _sharedHelper ??= await SharedHelper.init();

    await _sharedHelper?.increaseGamesStarted(gameMode);
  }

  /// Reset game variables
  void resetGame() {
    _gameOver = true;
    _mineField.clear();
    _flagCount = _mineCount;
    _openedTileCount = 0;
    _gameHasStarted = false;
    _gameOver = false;
    _timeElapsed = 0;
    GameAudioPlayer.playable = true;
    notifyListeners();
  }

  /// Exit game function
  void exitGame(BuildContext context) {
    // 2024-02-01 因为和音乐播放器共用一个player，退出扫雷游戏是，停止当前音乐播放
    GameAudioPlayer().resetPlayer(true);

    if (isMineAnimationOn) {
      minesAnimation = false;
    } else if (gameHasStarted) {
      GamePopupScreen.exitGame(context, this);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MinesweeperHomeView(),
          ),
          (route) => false,
        );
      });
    }
  }

  /// Win game function
  Future<void> winTheGame() async {
    _gameOver = true;
    notifyListeners();

    _audioPlayer.playAudio(GameSounds.lastHit);
    await Future.delayed(const Duration(milliseconds: 1500), () {
      _audioPlayer.playAudio(GameSounds.win, loop: true);
    });
  }

  /// Lose game function
  Future<void> loseTheGame() async {
    _gameOver = true;
    notifyListeners();
    await showAllMines();
    _audioPlayer.playAudio(GameSounds.lose, loop: true);
  }

  /// Places mines to empty game board. The number of mines depends on the game difficulty.
  void _placeMines(Tile tile) {
    var rnd = Random();
    int mines = _mineCount;
    int row = tile.row;
    int col = tile.col;

    while (mines > 0) {
      var i = rnd.nextInt(_boardLength);
      var j = rnd.nextInt(10);

      List<List<int>> restricted = [
        [row - 1, col - 1],
        [row - 1, col],
        [row - 1, col + 1],
        [row, col - 1],
        [row, col],
        [row, col + 1],
        [row + 1, col - 1],
        [row + 1, col],
        [row + 1, col + 1],
      ];

      if (restricted.any((element) => element[0] == i && element[1] == j)) {
        continue;
      }

      if (!_mineField[i][j].hasMine) {
        _mineField[i][j].setMine = true;
        mines--;
      }
    }
  }

  /// Remove/Add flag from/to specified tile
  void placeFlag(Tile tile) {
    if (!_gameOver) {
      bool flagValue = !tile.hasFlag;
      _mineField[tile.row][tile.col].setFlag = flagValue;
      _flagCount += flagValue ? -1 : 1;
      notifyListeners();
      _audioPlayer
          .playAudio(flagValue ? GameSounds.putFlag : GameSounds.removeFlag);
    }
  }

  /// When user clicks a tile, this function calls the [_openTile] function and starts the game if it is the first move of user's
  Future<bool?>? clickTile(Tile tile) async {
    if (!_gameHasStarted) {
      startGame(tile);
    } else if (!_gameOver) {
      return await _openTile(tile.row, tile.col, playSound: true);
    }
    return null;
  }

  /// Opens the clicked tile. Calls the [checkMinesAround] function and updates
  /// the tile value as mine count.
  Future<bool?>? _openTile(int row, int col, {bool playSound = false}) async {
    if (row < 0 ||
        col < 0 ||
        row >= mineField.length ||
        col >= mineField[0].length) return null;
    if (mineField[row][col].visible) return null;
    if (mineField[row][col].hasMine) {
      mineField[row][col].setVisible = true;
      _audioPlayer.playAudio(GameSounds.mineSound[0]);
      await loseTheGame();
      return false;
    }

    _openedTileCount++;
    int minesAround = checkMinesAround(row, col);
    mineField[row][col].setValue = minesAround;
    if (mineField[row][col].hasFlag) {
      _flagCount += 1;
    }
    notifyListeners();

    if (_openedTileCount + _mineCount == _boardLength * 10) {
      await winTheGame();
      return true;
    } else {
      if (playSound) {
        _audioPlayer.playAudio(GameSounds.clickSounds[
            minesAround >= GameSounds.clickSounds.length
                ? GameSounds.clickSounds.length - 1
                : minesAround]);
      }
      if (minesAround == 0) {
        _openTile(row + 1, col - 1);
        _openTile(row + 1, col);
        _openTile(row + 1, col + 1);
        _openTile(row, col - 1);
        _openTile(row, col + 1);
        _openTile(row - 1, col - 1);
        _openTile(row - 1, col);
        _openTile(row - 1, col + 1);
      }
    }
    return null;
  }

  /// Checks for surrounding mines and returns number of mines
  int checkMinesAround(int row, int col) {
    int rowLength = mineField.length;
    int colLength = mineField[0].length;

    int minesAround = 0;

    if (row - 1 >= 0) {
      // top-left
      if (col - 1 >= 0 && mineField[row - 1][col - 1].hasMine) {
        minesAround++;
      } // top
      if (mineField[row - 1][col].hasMine) {
        minesAround++;
      } // top-right
      if (col + 1 < colLength && mineField[row - 1][col + 1].hasMine) {
        minesAround++;
      }

      if (mineField[row - 1][col].visible == false) {
        mineField[row - 1][col].addBorder = 3;
      }
    }

    // left
    if (col - 1 >= 0) {
      if (mineField[row][col - 1].hasMine) {
        minesAround++;
      }
      if (mineField[row][col - 1].visible == false) {
        mineField[row][col - 1].addBorder = 2;
      }
    }
    // right
    if (col + 1 < colLength) {
      if (mineField[row][col + 1].hasMine) {
        minesAround++;
      }
      if (mineField[row][col + 1].visible == false) {
        mineField[row][col + 1].addBorder = 0;
      }
    }

    if (row + 1 < rowLength) {
      // bottom-left
      if (col - 1 >= 0 && mineField[row + 1][col - 1].hasMine) {
        minesAround++;
      } // bottom
      if (mineField[row + 1][col].hasMine) {
        minesAround++;
      } // bottom-right
      if (col + 1 < colLength && mineField[row + 1][col + 1].hasMine) {
        minesAround++;
      }
      if (mineField[row + 1][col].visible == false) {
        mineField[row + 1][col].addBorder = 1;
      }
    }

    return minesAround;
  }
}
