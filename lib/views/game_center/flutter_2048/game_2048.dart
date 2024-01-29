import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

import 'components/button.dart';
import 'components/empty_board.dart';
import 'components/score_board.dart';
import 'components/tile_board.dart';
import 'const/colors.dart';
import 'managers/board.dart';

///
/// 2024-01-26 此小游戏的实现完全来自 https://github.com/angjelkom/flutter_2048/tree/main
/// 正如它博文的初衷：is not to learn “How to make a game in Flutter” ，
/// but How to implement AnimationWidget and Explicit Animations,
/// manage and control them using AnimationController and state management solutions like Riverpod
///
class InitGame2048 extends StatefulWidget {
  const InitGame2048({super.key});

  @override
  State<InitGame2048> createState() => _InitGame2048State();
}

class _InitGame2048State extends State<InitGame2048> {
  @override
  void initState() {
    super.initState();

    initGame();
  }

  initGame() async {
    WidgetsFlutterBinding.ensureInitialized();

    await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: Game2048(),
    );
  }
}

/// 2024-01-29
/// 原示例是单个app实现2048项目，返回退出游戏关闭app时才记录当时的棋盘状态，再下一次进入时加载
/// 而这里整合到了一个子模块中，就不再是继承WidgetsBindingObserver并在didChangeAppLifecycleState()
/// 的inactive状态时才保存，而是退出页面时就保存
///
/// (如何更精确，就每移动一步就调用一次保存，即直接在状态管理中endRound之后，就立即保存)
class Game2048 extends ConsumerStatefulWidget {
  const Game2048({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GameState();
}

// Ticker 是一个特殊的计时器，每次绘制新帧时都会调用它，
// 在 60 FPS 的标准设备上，这意味着一秒钟内将调用 Ticket 60 次，
// 在 120 FPS 上，这意味着它将在一秒钟内调用 120 次。
class _GameState extends ConsumerState<Game2048> with TickerProviderStateMixin {
  /// 动画控制器
  ///  _moveController 将用于控制图块移动时的动画动画，
  /// _scaleController 将用于控制图块合并时的弹出效果，
  /// 并且每个控制器都有一个 CurveAnimation 作为子控制器。

  // The contoller used to move the the tiles
  late final AnimationController _moveController = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
  )..addStatusListener((status) {
      // 当图块移动动作结束后，合并图块并启动缩放动画，从而产生一个弹出的动画效果。
      if (status == AnimationStatus.completed) {
        // 条用状态合并函数
        ref.read(boardManager.notifier).merge();
        // 触发弹出动画效果
        _scaleController.forward(from: 0.0);
      }
    });

  // The curve animation for the move animation controller.
  late final CurvedAnimation _moveAnimation = CurvedAnimation(
    parent: _moveController,
    curve: Curves.easeInOut,
  );

  //The contoller used to show a popup effect when the tiles get merged
  // 当缩放动画完成时，通过调用 BoardManager 的 endRound 方法来结束回合，
  // 并且相同的方法将返回一个布尔值，无论是否开始下一个方向的移动，
  //    如果开始了，将再次启动 _moveController向前呼叫。
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addStatusListener((status) {
      //When the scale animation finishes end the round and if there is a queued movement start the move controller again for the next direction.
      // 当缩放动画结束时，结束该回合，如果有移动队列，则再次启动移动控制器进行下一个方向的移动。
      if (status == AnimationStatus.completed) {
        if (ref.read(boardManager.notifier).endRound()) {
          _moveController.forward(from: 0.0);
        }
      }
    });

  //The curve animation for the scale animation controller.
  late final CurvedAnimation _scaleAnimation = CurvedAnimation(
    parent: _scaleController,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    //Dispose the animations.以避免内存泄露
    _moveAnimation.dispose();
    _scaleAnimation.dispose();
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        //Move the tile with the arrows on the keyboard on Desktop
        if (ref.read(boardManager.notifier).onKey(event)) {
          _moveController.forward(from: 0.0);
        }
      },
      child: SwipeDetector(
        onSwipe: (direction, offset) {
          if (ref.read(boardManager.notifier).move(direction)) {
            _moveController.forward(from: 0.0);
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              '2048',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 56.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Expanded(flex: 2, child: MaxValueBoard()),
                        ],
                      ),
                      SizedBox(height: 10.sp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const ScoreBoard(),
                          SizedBox(width: 16.sp),
                          ButtonWidget(
                            icon: Icons.undo,
                            onPressed: () {
                              //Undo the round.
                              ref.read(boardManager.notifier).undo();
                            },
                          ),
                          SizedBox(width: 8.sp),
                          ButtonWidget(
                            icon: Icons.refresh,
                            onPressed: () {
                              //Restart the game
                              ref.read(boardManager.notifier).newGame();
                            },
                          )
                        ],
                      )
                    ],
                  )),
              SizedBox(height: 32.sp),
              Stack(
                children: [
                  const EmptyBoardWidget(),
                  // 将移动和缩放动画传递给 TileBoardWiget
                  TileBoardWidget(
                    moveAnimation: _moveAnimation,
                    scaleAnimation: _scaleAnimation,
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
