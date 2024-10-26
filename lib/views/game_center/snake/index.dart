// ignore_for_file: curly_braces_in_flow_control_structures, constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../services/my_get_storage.dart';
import '../../../services/service_locator.dart';

// 2024-01-31 蛇头方向的枚举
enum SnakeHead {
  LEFT,
  RIGHT,
  UP,
  DOWN,
}

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

  // 当前得分
  late int _playerScore;

  // 缓存中的最佳得分
  late int _bsetScore;

  // 是否已经开始(true为还没开始？因为init的时候设置为true，蛇是静止的，下方也是显示开始按钮)
  late bool _hasStarted;
  // 蛇的动画
  late Animation<double> _snakeAnimation;
  // 蛇的控制器
  late AnimationController _snakeController;
  // 蛇的初始位置和长度(蛇头在数字大的那边)
  List _snake = [304, 305, 306, 307];

  ///  用gridview创建游戏区域的棋盘，
  /// _squareSize表示一行多少个方块，_noOfSquares + _squareSize表示方块总数量
  final int _noOfSquares = 380;
  final int _squareSize = 20;

  // 动画的速度(理论上应该和下面蛇的速度的定时器一致，
  // 不然可能出现蛇移动很慢动画更新很快也没意义，或者蛇已经走了，但动画没更新？？？实际上没出现这种情况)
  final Duration _duration = const Duration(milliseconds: 250);
  // 当前蛇前进的方形(用于控制改变)
  late SnakeHead _currentSnakeDirection;
  // 蛇的食物出现的位置
  late int _snakeFoodPosition;
  // 随机函数实例
  final Random _random = Random();

  // 游戏结束在当前页面上方显示一个浮层
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _setUpGame();
  }

  List<int> getRandomSublist(List<int> list) {
    Random random = Random();
    // 随机选择起始索引，确保剩余空间可以容纳长度为4的子列表
    int startIndex = random.nextInt(list.length - 3);
    // 返回从startIndex开始的长度为4的子列表
    return list.sublist(startIndex, startIndex + 4);
  }

  void _setUpGame() {
    _bsetScore = _simpleStorage.getSnakeBestScore() ?? 0;
    _playerScore = 0;

    // 每次都随机生成初始蛇列表
    _snake = getRandomSublist(
      List.generate(_noOfSquares + _squareSize, (index) => index),
    );
    _currentSnakeDirection = SnakeHead.RIGHT;
    _hasStarted = true;
    do {
      // 食物随机出现在某一个格子里面
      _snakeFoodPosition = _random.nextInt(_noOfSquares);
    } while (_snake.contains(_snakeFoodPosition));

    _snakeController = AnimationController(
      vsync: this,
      duration: _duration,
    );

    _snakeAnimation = CurvedAnimation(
      curve: Curves.easeInOut,
      parent: _snakeController,
    );
  }

  void _gameStart() {
    // 蛇的速度
    Timer.periodic(const Duration(milliseconds: 250), (Timer timer) {
      _updateSnake();
      if (_hasStarted) timer.cancel();
    });
  }

  // 如果表示蛇的列表的最后一个元素（蛇头）是蛇列表中任何一个，表示蛇碰到自己了，游戏结束
  bool _gameOver() {
    for (int i = 0; i < _snake.length - 1; i++) {
      if (_snake.last == _snake[i]) {
        return true;
      }
    }
    return false;
  }

  void _updateSnake() async {
    if (!_hasStarted) {
      if (!mounted) return;
      setState(() {
        // 当前分数就是吃掉的食物的数量*100
        _playerScore = (_snake.length - 4) * 100;

        // 如果方向有修改，进行相关判断
        switch (_currentSnakeDirection) {
          case SnakeHead.DOWN:
            // 方向朝下时，如果蛇头已经超过了最后一行，则从第一行出来；
            // 如果还在中间范围，就是正常向下一行(即加1行的数量)
            // 其他同理，不过左右就是单纯数字1而不是1行的数量了
            if (_snake.last > _noOfSquares) {
              _snake.add(
                _snake.last + _squareSize - (_noOfSquares + _squareSize),
              );
            } else {
              _snake.add(_snake.last + _squareSize);
            }
            break;
          case SnakeHead.UP:
            if (_snake.last < _squareSize) {
              _snake.add(
                _snake.last - _squareSize + (_noOfSquares + _squareSize),
              );
            } else {
              _snake.add(_snake.last - _squareSize);
            }
            break;
          case SnakeHead.RIGHT:
            if ((_snake.last + 1) % _squareSize == 0) {
              _snake.add(_snake.last + 1 - _squareSize);
            } else {
              _snake.add(_snake.last + 1);
            }
            break;
          case SnakeHead.LEFT:
            if ((_snake.last) % _squareSize == 0) {
              _snake.add(_snake.last - 1 + _squareSize);
            } else {
              _snake.add(_snake.last - 1);
            }
        }

        // 上面方向改变的操作，是在列表last(也就是蛇头)添加了一个元素，
        // 因此如果转向没有吃到食物，则需要把蛇尾从列表移除(即移除列表索引第一个元素)
        if (_snake.last != _snakeFoodPosition) {
          _snake.removeAt(0);
        } else {
          // 如果吃到了食物，就要随机再生成一个新的食物
          do {
            _snakeFoodPosition = _random.nextInt(_noOfSquares);
          } while (_snake.contains(_snakeFoodPosition));
        }

        // 如果游戏结束了(蛇头碰到了蛇身)，重置游戏开始状态并跳转到游戏结束页面
        if (_gameOver()) {
          if (!mounted) return;
          setState(() {
            _hasStarted = !_hasStarted;
          });

          // 这里原本是跳转到新的gameover页面
          // ？？？其实如果和其他小游戏类似的话，就直接当前页面提示失败就好，不要跳转新页面
          // 这是一个简单的overlay示例
          _showGameOverOverlay(context);
        }
      });
    }
  }

  void _showGameOverOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '游戏结束',
                  style: TextStyle(
                    // 取消overlay中文字的下划线
                    decoration: TextDecoration.none,
                    color: Colors.redAccent,
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(
                        offset: Offset(-1.5, -1.5),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.5, -1.5),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(1.5, 1.5),
                        color: Colors.black,
                      ),
                      Shadow(
                        offset: Offset(-1.5, 1.5),
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25.sp),
                Text(
                  '游戏得分: $_playerScore',
                  style: TextStyle(
                    // 取消overlay中文字的下划线
                    decoration: TextDecoration.none,
                    fontSize: 24.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 25.sp),
                ElevatedButton(
                  onPressed: () async {
                    _overlayEntry?.remove();

                    // 2023-02-01 更新完当前得分后更新最佳得分
                    // 之前放在_updateSnake中，则会出现在达到最高分之后，每吃一次食物就因为更新最大值而卡顿的问题
                    if (_playerScore > _bsetScore) {
                      await _simpleStorage.setSnakeBestScore(_playerScore);
                      if (!mounted) return;
                      setState(() {
                        _bsetScore = _playerScore;
                      });
                    }

                    if (!mounted) return;
                    setState(() {
                      _setUpGame();
                    });
                  },
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    });

    Overlay.of(context).insert(_overlayEntry!); // 插入overlay
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 手势控制蛇前进的方向
        child: GestureDetector(
          onVerticalDragUpdate: (drag) {
            if (drag.delta.dy > 0 && _currentSnakeDirection != SnakeHead.UP) {
              _currentSnakeDirection = SnakeHead.DOWN;
            } else if (drag.delta.dy < 0 &&
                _currentSnakeDirection != SnakeHead.DOWN)
              _currentSnakeDirection = SnakeHead.UP;
          },
          onHorizontalDragUpdate: (drag) {
            if (drag.delta.dx > 0 && _currentSnakeDirection != SnakeHead.LEFT) {
              _currentSnakeDirection = SnakeHead.RIGHT;
            } else if (drag.delta.dx < 0 &&
                _currentSnakeDirection != SnakeHead.RIGHT)
              _currentSnakeDirection = SnakeHead.LEFT;
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(20.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      '当前得分: $_playerScore',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    Text(
                      '最佳得分: $_bsetScore',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: GridView.builder(
                  // 不管原始设计如何，我都修改为20*20的量
                  // 避免修改原逻辑，只是把_noOfSquares值改动了
                  itemCount: _squareSize + _noOfSquares,
                  shrinkWrap: true, // 设置为true以避免GridView高度冲突
                  physics: const NeverScrollableScrollPhysics(), // 禁止GridView滚动
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _squareSize,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return Center(
                      // 方块的背景色
                      child: Container(
                        color: const Color.fromARGB(127, 158, 173, 134),
                        padding: _snake.contains(index)
                            ? EdgeInsets.all(0.5.sp)
                            : EdgeInsets.all(0.3.sp),

                        // 如果是食物或者蛇头的方块，就使用圆角部件，且圆弧大一些circular(7)；
                        // 如果是蛇身，圆弧就稍微小一些circular(2.5)；
                        // 如果是正常背景，圆弧就再小一些circular(1)(有这个圆弧时为了稍微显示一下背景的方块边框)
                        // 但现在我将上方padding默认留有边框线，这最后一个其实可以不用圆弧了
                        child: ClipRRect(
                          borderRadius: index == _snakeFoodPosition ||
                                  index == _snake.last
                              ? BorderRadius.circular(7)
                              : _snake.contains(index)
                                  ? BorderRadius.circular(2.5)
                                  : BorderRadius.circular(0),
                          // 属于蛇身体的为黑色，食物为绿色，背景为蓝色
                          child: Container(
                            color: _snake.contains(index)
                                ? Colors.black
                                : index == _snakeFoodPosition
                                    ? Colors.green
                                    : const Color.fromARGB(127, 138, 152, 117),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FractionallySizedBox(
                      widthFactor: 0.5, // 设置宽度为父容器的一半
                      child: ElevatedButton.icon(
                        label: Text(_hasStarted ? '开始' : '暂停'),
                        onPressed: () {
                          setState(() {
                            if (_hasStarted) {
                              _snakeController.forward();
                            } else {
                              _snakeController.reverse();
                            }
                            _hasStarted = !_hasStarted;
                            _gameStart();
                          });
                        },
                        icon: AnimatedIcon(
                          icon: AnimatedIcons.play_pause,
                          progress: _snakeAnimation,
                        ),
                        // 给按钮添加了圆弧
                        style: ButtonStyle(
                          shape: WidgetStateProperty.resolveWith(
                            (Set<WidgetState> states) {
                              return RoundedRectangleBorder(
                                // 指定圆角半径
                                borderRadius: BorderRadius.circular(20),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ？？？这里的方向键还可以设定按钮的节流，就是在比如上方动画间隔时间内重复点击了按钮，只让第一次生效
                  // 简单实现可以有一个_isButtonEnabled 标识，在onPressed前判断是否为true，
                  //    如果是true，点击后置为false，然后设置一个延迟函数，250ms之后再置为true
                  //    如果是false，点击不作为(例如onPressed置为null)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.arrow_back, size: 32.sp),
                          onPressed: () {
                            // 2024-01-13 注意按键的逻辑：
                            // 只有当前方向是向左或者向右时候，才能改变为上下；
                            // 同理，只有当前方向是上下时，才能改变为左右。

                            // 这也是上面手势滑动类似，例如垂直向下滑动、且方向不是UP时才会调转蛇头为向下
                            // <=> 点击向下按钮，只有当前方向是LEFT 或者RIGHT才生效
                            if (_currentSnakeDirection == SnakeHead.UP ||
                                _currentSnakeDirection == SnakeHead.DOWN) {
                              _currentSnakeDirection = SnakeHead.LEFT;
                            }
                          },
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.arrow_upward, size: 32.sp),
                              onPressed: () {
                                if (_currentSnakeDirection == SnakeHead.LEFT ||
                                    _currentSnakeDirection == SnakeHead.RIGHT) {
                                  _currentSnakeDirection = SnakeHead.UP;
                                }
                              },
                            ),
                            SizedBox(height: 32.sp),
                            IconButton(
                              icon: Icon(Icons.arrow_downward, size: 32.sp),
                              onPressed: () {
                                if (_currentSnakeDirection == SnakeHead.LEFT ||
                                    _currentSnakeDirection == SnakeHead.RIGHT) {
                                  _currentSnakeDirection = SnakeHead.DOWN;
                                }
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward, size: 32.sp),
                          onPressed: () {
                            if (_currentSnakeDirection == SnakeHead.UP ||
                                _currentSnakeDirection == SnakeHead.DOWN) {
                              _currentSnakeDirection = SnakeHead.RIGHT;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
