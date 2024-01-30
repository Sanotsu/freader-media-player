import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../services/my_get_storage.dart';
import '../../../../services/service_locator.dart';
import '../const/constant.dart';
import '../material/audios.dart';
import 'block.dart';

///state of [GameControl]
enum GameStates {
  ///随时可以开启一把惊险而又刺激的俄罗斯方块
  none,

  ///游戏暂停中，方块的下落将会停止
  paused,

  ///游戏正在进行中，方块正在下落
  ///按键可交互
  running,

  ///游戏正在重置
  ///重置完成之后，[GameController]状态将会迁移为[none]
  reset,

  ///下落方块已经到达底部，此时正在将方块固定在游戏矩阵中
  ///固定完成之后，将会立即开始下一个方块的下落任务
  mixing,

  ///正在消除行
  ///消除完成之后，将会立刻开始下一个方块的下落任务
  clear,

  ///方块快速下坠到底部
  drop,
}

class Game extends StatefulWidget {
  final Widget child;

  const Game({super.key, required this.child});

  @override
  State<StatefulWidget> createState() {
    return GameControl();
  }

  static GameControl of(BuildContext context) {
    final state = context.findAncestorStateOfType<GameControl>();
    assert(state != null, "must wrap this context with [Game]");
    return state!;
  }
}

class GameControl extends State<Game> with RouteAware {
  GameControl() {
    //inflate game pad data
    for (int i = 0; i < GAME_PAD_MATRIX_H; i++) {
      _data.add(List.filled(GAME_PAD_MATRIX_W, 0));
      _mask.add(List.filled(GAME_PAD_MATRIX_W, 0));
    }
  }

  // 2024-01-30 这个不清楚有什么用，注释掉，如果不影响后续就删掉
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   routeObserver.subscribe(this, ModalRoute.of(context)!);
  // }

  // @override
  // void dispose() {
  //   routeObserver.unsubscribe(this);
  //   super.dispose();
  // }

  @override
  void didPushNext() {
    //pause when screen is at background
    pause();
  }

  ///the gamer data
  final List<List<int>> _data = [];

  ///在 [build] 方法中于 [_data]混合，形成一个新的矩阵
  ///[_mask]矩阵的宽高与 [_data] 一致
  ///对于任意的 _mask[x,y] ：
  /// 如果值为 0,则对 [_data]没有任何影响
  /// 如果值为 -1,则表示 [_data] 中该行不显示
  /// 如果值为 1，则表示 [_data] 中该行高亮
  final List<List<int>> _mask = [];

  ///from 1-6
  int _level = 1;

  int _points = 0;

  int _cleared = 0;

  Block? _current;

  Block _next = Block.getRandom();

  GameStates _states = GameStates.none;

  // 2024-01-30 加一个历史最高得分，在初始化的时候就从缓存中获取
  final _simpleStorage = getIt<MyGetStorage>();
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _bestScore = _simpleStorage.getTetrisBestScore() ?? 0;
  }

  Block _getNext() {
    final next = _next;
    _next = Block.getRandom();
    return next;
  }

  SoundState get _sound => Sound.of(context);

  /// 这里是主要的点击了4个方向键和下落按钮的逻辑，其中方向键上是方块变形
  /// 各自的setState(() {});是为了更新方块的状态
  void rotate() {
    if (_states == GameStates.running) {
      final next = _current?.rotate();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        _sound.rotate();
      }
    }
    setState(() {});
  }

  void right() {
    if (_states == GameStates.none && _level < LEVEL_MAX) {
      _level++;
    } else if (_states == GameStates.running) {
      final next = _current?.right();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        _sound.move();
      }
    }
    setState(() {});
  }

  void left() {
    if (_states == GameStates.none && _level > LEVEL_MIN) {
      _level--;
    } else if (_states == GameStates.running) {
      final next = _current?.left();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        _sound.move();
      }
    }
    setState(() {});
  }

  void drop() async {
    if (_states == GameStates.running) {
      for (int i = 0; i < GAME_PAD_MATRIX_H; i++) {
        final fall = _current?.fall(step: i + 1);
        if (fall != null && !fall.isValidInMatrix(_data)) {
          _current = _current?.fall(step: i);
          _states = GameStates.drop;
          if (!mounted) return;
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 100));
          _mixCurrentIntoData(mixSound: _sound.fall);
          break;
        }
      }
      if (!mounted) return;
      setState(() {});
    } else if (_states == GameStates.paused || _states == GameStates.none) {
      _startGame();
    }
  }

  void down({bool enableSounds = true}) {
    if (_states == GameStates.running) {
      final next = _current?.fall();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        if (enableSounds) {
          _sound.move();
        }
      } else {
        _mixCurrentIntoData();
      }
    }
    // 2024-01-30 这个setState的作用，看起来应该是更新方块降落的状态。
    // 但目前直接使用有点问题，在游戏过程中返回上一页就会报错：
    // Unhandled Exception: setState() called after dispose(): GameControl#af308(lifecycle state: defunct, not mounted)
    // 所以添加了一个判断是否挂载，如果已经没有挂载了，就直接返回，这样就不会保存了
    // 理论上这里的状态更新前都应该判断一下，但目前其他状态在dispose后似乎没有继续更新的情况，所以大部分暂时不添加。
    // 这个问题参看：https://stackoverflow.com/questions/63592887/fluttererror-setstate-called-after-dispose-lifecycle-state-defunct-not
    if (!mounted) return;
    setState(() {});
  }

  Timer? _autoFallTimer;

  ///mix current into [_data]
  Future<void> _mixCurrentIntoData({VoidCallback? mixSound}) async {
    if (_current == null) {
      return;
    }
    //cancel the auto falling task
    _autoFall(false);

    _forTable((i, j) => _data[i][j] = _current?.get(j, i) ?? _data[i][j]);

    //消除行
    final clearLines = [];
    for (int i = 0; i < GAME_PAD_MATRIX_H; i++) {
      if (_data[i].every((d) => d == 1)) {
        clearLines.add(i);
      }
    }

    if (clearLines.isNotEmpty) {
      setState(() => _states = GameStates.clear);

      _sound.clear();

      ///消除效果动画
      for (int count = 0; count < 5; count++) {
        for (var line in clearLines) {
          _mask[line].fillRange(0, GAME_PAD_MATRIX_W, count % 2 == 0 ? -1 : 1);
        }
        if (!mounted) return;
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 100));
      }
      for (var line in clearLines) {
        _mask[line].fillRange(0, GAME_PAD_MATRIX_W, 0);
      }

      //移除所有被消除的行
      for (var line in clearLines) {
        _data.setRange(1, line + 1, _data);
        _data[0] = List.filled(GAME_PAD_MATRIX_W, 0);
      }
      debugPrint("clear lines : $clearLines");

      _cleared += clearLines.length;
      _points += clearLines.length * _level * 5;

      // 2024-01-30 每次得分，都要和历史最佳做比较
      _bestScore = max(_points, (_simpleStorage.getTetrisBestScore() ?? 0));
      await _simpleStorage.setTetrisBestScore(_bestScore);

      //up level possible when cleared
      int level = (_cleared ~/ 50) + LEVEL_MIN;
      _level = level <= LEVEL_MAX && level > _level ? level : _level;
    } else {
      _states = GameStates.mixing;
      mixSound?.call();
      _forTable((i, j) => _mask[i][j] = _current?.get(j, i) ?? _mask[i][j]);
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
      _forTable((i, j) => _mask[i][j] = 0);
      if (!mounted) return;
      setState(() {});
    }

    //_current已经融入_data了，所以不再需要
    _current = null;

    //检查游戏是否结束,即检查第一行是否有元素为1
    if (_data[0].contains(1)) {
      reset();
      return;
    } else {
      //游戏尚未结束，开启下一轮方块下落
      _startGame();
    }
  }

  ///遍历表格
  ///i 为 row
  ///j 为 column
  static void _forTable(dynamic Function(int row, int column) function) {
    for (int i = 0; i < GAME_PAD_MATRIX_H; i++) {
      for (int j = 0; j < GAME_PAD_MATRIX_W; j++) {
        final b = function(i, j);
        if (b is bool && b) {
          break;
        }
      }
    }
  }

  void _autoFall(bool enable) {
    if (!enable) {
      _autoFallTimer?.cancel();
      _autoFallTimer = null;
    } else if (enable) {
      _autoFallTimer?.cancel();
      _current = _current ?? _getNext();
      _autoFallTimer = Timer.periodic(SPEED[_level - 1], (t) {
        down(enableSounds: false);
      });
    }
  }

  void pause() {
    if (_states == GameStates.running) {
      _states = GameStates.paused;
    }
    setState(() {});
  }

  void pauseOrResume() {
    if (_states == GameStates.running) {
      pause();
    } else if (_states == GameStates.paused || _states == GameStates.none) {
      _startGame();
    }
  }

  void reset() {
    if (_states == GameStates.none) {
      //可以开始游戏
      _startGame();
      return;
    }
    if (_states == GameStates.reset) {
      return;
    }
    _sound.start();
    _states = GameStates.reset;
    () async {
      int line = GAME_PAD_MATRIX_H;
      await Future.doWhile(() async {
        line--;
        for (int i = 0; i < GAME_PAD_MATRIX_W; i++) {
          _data[line][i] = 1;
        }
        setState(() {});
        await Future.delayed(REST_LINE_DURATION);
        return line != 0;
      });
      _current = null;
      _getNext();
      _points = 0;
      _cleared = 0;
      await Future.doWhile(() async {
        for (int i = 0; i < GAME_PAD_MATRIX_W; i++) {
          _data[line][i] = 0;
        }
        setState(() {});
        line++;
        await Future.delayed(REST_LINE_DURATION);
        return line != GAME_PAD_MATRIX_H;
      });
      setState(() {
        _states = GameStates.none;
      });
    }();
  }

  void _startGame() {
    if (_states == GameStates.running && _autoFallTimer?.isActive == false) {
      return;
    }
    _states = GameStates.running;
    _autoFall(true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List<List<int>> mixed = [];
    for (var i = 0; i < GAME_PAD_MATRIX_H; i++) {
      mixed.add(List.filled(GAME_PAD_MATRIX_W, 0));
      for (var j = 0; j < GAME_PAD_MATRIX_W; j++) {
        int value = _current?.get(j, i) ?? _data[i][j];
        if (_mask[i][j] == -1) {
          value = 0;
        } else if (_mask[i][j] == 1) {
          value = 2;
        }
        mixed[i][j] = value;
      }
    }
    debugPrint("game states : $_states");
    return GameState(
      mixed,
      _states,
      _level,
      _sound.mute,
      _points,
      _bestScore,
      _cleared,
      _next,
      child: widget.child,
    );
  }

  void soundSwitch() {
    setState(() {
      _sound.mute = !_sound.mute;
    });
  }
}

class GameState extends InheritedWidget {
  const GameState(
    this.data,
    this.states,
    this.level,
    this.muted,
    this.points,
    this.bestScore,
    this.cleared,
    this.next, {
    super.key,
    required this.child,
  }) : super(child: child);

  @override
  // ignore: overridden_fields
  final Widget child;

  ///屏幕展示数据
  ///0: 空砖块
  ///1: 普通砖块
  ///2: 高亮砖块
  final List<List<int>> data;

  final GameStates states;

  final int level;

  final bool muted;

  final int points;

  // 2024-01-30 历史最高得分
  final int bestScore;

  final int cleared;

  final Block next;

  static GameState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GameState>()!;
  }

  @override
  bool updateShouldNotify(GameState oldWidget) {
    return true;
  }
}
