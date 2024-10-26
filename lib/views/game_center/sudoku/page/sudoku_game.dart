import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../constant.dart';
import '../effect/sound_effect.dart';
import '../state/sudoku_state.dart';
import '../util/localization_util.dart';
import 'sudoku_pause_cover.dart';

final Logger log = Logger();

String sudokuImagePre = "assets/games/sodoku/image";

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black54,
  shadowColor: Colors.blue,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

final ButtonStyle primaryFlatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.white,
  backgroundColor: Colors.lightBlue,
  shadowColor: Colors.blue,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(3.0)),
  ),
);

Image ideaPng = Image(
  image: AssetImage("$sudokuImagePre/icon_idea.png"),
  width: 25,
  height: 25,
);
Image lifePng = Image(
  image: AssetImage("$sudokuImagePre/icon_life.png"),
  width: 25,
  height: 25,
);

class SudokuGamePage extends StatefulWidget {
  const SudokuGamePage({super.key, required this.title});
  final String title;

  @override
  State<SudokuGamePage> createState() => _SudokuGamePageState();
}

class _SudokuGamePageState extends State<SudokuGamePage>
    with WidgetsBindingObserver {
  int _chooseSudokuBox = 0;
  bool _markOpen = false;
  bool _manualPause = false;

  SudokuState get _state => ScopedModel.of<SudokuState>(context);

  _aboutDialogAction(BuildContext context) {
    Widget appIcon = GestureDetector(
      child: Image(
        image: AssetImage("$sudokuImagePre/sudoku_logo.png"),
        width: 45,
        height: 45,
      ),
      onDoubleTap: () {
        columnWidget(BuildContext context) {
          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image(
                  image: AssetImage("$sudokuImagePre/sudoku_logo.png"),
                ),
                CupertinoButton(
                  child: const Text("Sudoku"),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                )
              ]);
        }

        showDialog(context: context, builder: columnWidget);
      },
    );

    return showAboutDialog(
      applicationIcon: appIcon,
      context: context,
      children: <Widget>[
        GestureDetector(
          child: const Text(
            "Github Repository",
            style: TextStyle(color: Colors.blue),
          ),
          // onTap: () async {
          //   if (await canLaunchUrlString(Constant.githubRepository)) {
          //     if (Platform.isAndroid) {
          //       await launchUrlString(Constant.githubRepository,
          //           mode: LaunchMode.platformDefault);
          //     } else {
          //       await launchUrlString(Constant.githubRepository,
          //           mode: LaunchMode.externalApplication);
          //     }
          //   } else {
          //     log.e("can't open browser to url : ${Constant.githubRepository}");
          //   }
          // },
        ),
        Container(
            margin: const EdgeInsets.fromLTRB(0, 10, 0, 5),
            padding: const EdgeInsets.all(0),
            child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sudoku powered by Flutter",
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    Constant.githubRepository,
                    style: TextStyle(fontSize: 12),
                  )
                ]))
      ],
    );
  }

  bool _isOnlyReadGrid(int index) => (_state.sudoku?.puzzle[index] ?? 0) != -1;

  // 游戏盘点，检查是否游戏结束
  // check the game is done
  void _gameStackCount() {
    if (_state.isComplete) {
      _pauseTimer();
      _state.updateStatus(SudokuGameStatus.success);
      return _gameOver();
    }
  }

  /// game over trigger function
  /// 游戏结束触发 执行判断逻辑
  void _gameOver() async {
    bool isWinner = _state.status == SudokuGameStatus.success;
    String title, conclusion;
    Function playSoundEffect;

    // @TODO this place wait for I18N support

    // define i18n begin
    const String elapsedTimeText = "耗时";
    const String winnerConclusionText = "恭喜你完成 [%level%] 数独挑战!";
    const String failureConclusionText = "很遗憾,本轮 [%level%] 数独错误次数太多，挑战失败!";
    final String levelLabel =
        LocalizationUtils.localizationLevelName(context, _state.level!);
    // define i18n end
    if (isWinner) {
      title = "厉害，干得漂亮!";
      conclusion = winnerConclusionText.replaceFirst("%level%", levelLabel);
      playSoundEffect = SoundEffect().solveVictory;
    } else {
      title = "可惜，就差一点!";
      conclusion = failureConclusionText.replaceFirst("%level%", levelLabel);
      playSoundEffect = SoundEffect().gameOver;
    }

    // route to game over show widget page
    PageRouteBuilder gameOverPageRouteBuilder = PageRouteBuilder(
      opaque: false,
      pageBuilder: (BuildContext context, animation, _) {
        // sound effect : victory or failure
        playSoundEffect();
        // game over show widget
        Widget gameOverWidget = Scaffold(
          backgroundColor: Colors.white.withOpacity(0.85),
          body: Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isWinner ? Colors.black : Colors.redAccent,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          25.0,
                          0.0,
                          25.0,
                          0.0,
                        ),
                        child: Text(
                          conclusion,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.fromLTRB(0, 15, 0, 10),
                        child: Text(
                          "$elapsedTimeText : ${_state.timer}'s",
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Offstage(
                              offstage:
                                  _state.status == SudokuGameStatus.success,
                              child: const IconButton(
                                icon: Icon(Icons.tv),
                                onPressed: null,
                              ),
                            ),
                            const IconButton(
                              icon: Icon(Icons.thumb_up),
                              onPressed: null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.exit_to_app),
                              onPressed: () {
                                Navigator.pop(context, "exit");
                              },
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );

        return ScaleTransition(
          scale: Tween(begin: 3.0, end: 1.0).animate(animation),
          child: gameOverWidget,
        );
      },
    );

    String signal = await Navigator.of(context).push(gameOverPageRouteBuilder);
    switch (signal) {
      case "ad":
        // @TODO give extra life logic coding
        // may do something to give user extra life , like watch ad video / make comment of this app ?
        break;
      case "exit":
      default:
        if (!mounted) return;
        Navigator.pop(context);
        break;
    }
  }

  // fill zone [ 1 - 9 ]
  Widget _fillZone(BuildContext context) {
    List<Widget> fillTools = List.generate(9, (index) {
      int num = index + 1;
      bool hasNumStock = _state.hasNumStock(num);
      Future<void> Function()? fillOnPressed;
      if (!hasNumStock) {
        fillOnPressed = null;
      } else {
        fillOnPressed = () async {
          log.d("input : $num");
          if (_isOnlyReadGrid(_chooseSudokuBox)) {
            // 非填空项
            return;
          }
          if (_state.status != SudokuGameStatus.gaming) {
            // 未在游戏进行时
            return;
          }
          if (_markOpen) {
            /// markOpen , mean use mark notes
            log.d("填写笔记");
            _state.switchMark(_chooseSudokuBox, num);
          } else {
            // 填写数字
            _state.switchRecord(_chooseSudokuBox, num);
            // 判断真伪
            if (_state.record[_chooseSudokuBox] != -1 &&
                _state.sudoku!.solution[_chooseSudokuBox] != num) {
              // 填入错误数字 wrong answer on _chooseSudokuBox with num
              _state.lifeLoss();
              if (_state.life <= 0) {
                // 游戏结束
                return _gameOver();
              }

              // "\nWrong Input\nYou can't afford ${_state.life} more turnovers"
              String wrongInputAlertText = "填写错误\n你还可以尝试 %attempts% 次";
              wrongInputAlertText = wrongInputAlertText.replaceFirst(
                "%attempts%",
                "${_state.life}",
              );
              String gotItText = "明白";

              showCupertinoDialog(
                  context: context,
                  builder: (context) {
                    // sound stuff error
                    SoundEffect().stuffError();
                    return CupertinoAlertDialog(
                      title: const Text("Oops..."),
                      content: Text(wrongInputAlertText),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(gotItText),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        )
                      ],
                    );
                  });

              return;
            }
            _gameStackCount();
          }
        };
      }

      Color recordFontColor = hasNumStock ? Colors.black : Colors.white;
      Color recordBgColor = hasNumStock ? Colors.black12 : Colors.white24;

      Color markFontColor = hasNumStock ? Colors.white : Colors.white;
      Color markBgColor = hasNumStock ? Colors.black : Colors.white24;

      return Expanded(
        flex: 1,
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: const BoxDecoration(border: BorderDirectional()),
          child: CupertinoButton(
            color: _markOpen ? markBgColor : recordBgColor,
            padding: const EdgeInsets.all(1),
            onPressed: fillOnPressed,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: _markOpen ? markFontColor : recordFontColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    });

    fillTools.add(
      Expanded(
        flex: 1,
        child: CupertinoButton(
          padding: const EdgeInsets.all(8),
          child: Image(
            image: AssetImage("$sudokuImagePre/icon_eraser.png"),
            width: 40,
            height: 40,
          ),
          onPressed: () {
            log.d("""
              when ${_chooseSudokuBox + 1} is not a puzzle , then clean the choose \n
              清除 ${_chooseSudokuBox + 1} 选型 , 如果他不是固定值的话
              """);
            if (_isOnlyReadGrid(_chooseSudokuBox)) {
              // read only item , skip it - 只读格
              return;
            }
            if (_state.status != SudokuGameStatus.gaming) {
              // not playing , skip it - 未在游戏进行时
              return;
            }
            _state.cleanMark(_chooseSudokuBox);
            _state.cleanRecord(_chooseSudokuBox);
          },
        ),
      ),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 40,
        width: MediaQuery.of(context).size.width,
        child: Row(children: fillTools),
      ),
    );
  }

  Widget _toolZone(BuildContext context) {
    // pause button tap function
    pauseOnPressed() {
      if (_state.status != SudokuGameStatus.gaming) {
        return;
      }

      // 标记手动暂停
      setState(() {
        _manualPause = true;
      });

      _pause();
      Navigator.push(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (BuildContext context, _, __) {
            return const SudokuPauseCoverPage();
          },
        ),
      ).then((_) {
        _gaming();

        // 解除手动暂停
        setState(() {
          _manualPause = false;
        });
      });
    }

    // tips button tap function
    // ignore: prefer_typing_uninitialized_variables
    var tipsOnPressed;
    if (_state.hint > 0) {
      tipsOnPressed = () {
        // tips next cell answer
        log.d("top tips button");
        int hint = _state.hint;
        if (hint <= 0) {
          return;
        }
        List<int> puzzle = _state.sudoku!.puzzle;
        List<int> solution = _state.sudoku!.solution;
        List<int> record = _state.record;
        // random point tips
        int randomBeginPoint = Random().nextInt(puzzle.length);
        for (int i = 0; i < puzzle.length; i++) {
          int index = (i + randomBeginPoint) % puzzle.length;
          if (puzzle[index] == -1 && record[index] == -1) {
            SoundEffect().answerTips();
            _state.setRecord(index, solution[index]);
            _state.hintLoss();
            _chooseSudokuBox = index;
            _gameStackCount();
            return;
          }
        }
      };
    }

    // mark button tap function
    markOnPressed() {
      log.d("enable mark function - 启用笔记功能");
      setState(() {
        _markOpen = !_markOpen;
      });
    }

    // define i18n text begin
    var exitGameText = "退出游戏";
    var cancelText = "取消";
    var pauseText = "暂停游戏";
    var tipsText = "随机提示";
    var enableMarkText = "启用笔记";
    var closeMarkText = "关闭笔记";
    var exitGameContentText = "是否要结束本轮数独？";
    // define i18n text end
    exitGameOnPressed() async {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text(
                exitGameText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(exitGameContentText),
              actions: [
                TextButton(
                  style: flatButtonStyle,
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text(exitGameText),
                ),
                TextButton(
                  style: primaryFlatButtonStyle,
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text(cancelText),
                ),
              ]);
        },
      ).then((val) {
        bool confirm = val;
        if (confirm == true) {
          // exit the game 退出游戏
          if (!context.mounted) return;
          ScopedModel.of<SudokuState>(context).initialize();
          Navigator.pop(context);
        }
      });
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      child: Row(
        children: <Widget>[
          // 暂停游戏
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                padding: const EdgeInsets.all(5),
                onPressed: pauseOnPressed,
                child: Text(
                  pauseText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          // tips 提示
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: CupertinoButton(
                padding: const EdgeInsets.all(5),
                onPressed: tipsOnPressed,
                child: Text(
                  tipsText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          // mark 笔记
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: CupertinoButton(
                padding: const EdgeInsets.all(5),
                onPressed: markOnPressed,
                child: Text(
                  _markOpen ? closeMarkText : enableMarkText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          ),
          // 退出
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: const EdgeInsets.all(5),
                onPressed: exitGameOnPressed,
                child: Text(
                  exitGameText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 计算网格背景色
  Color _gridInWellBgColor(int index) {
    Color gridWellBackgroundColor;
    // same zones
    List<int> zoneIndexes =
        Matrix.getZoneIndexes(zone: Matrix.getZone(index: index));
    // same rows
    List<int> rowIndexes = Matrix.getRowIndexes(Matrix.getRow(index));
    // same columns
    List<int> colIndexes = Matrix.getColIndexes(Matrix.getCol(index));

    Set indexSet = {};
    indexSet.addAll(zoneIndexes);
    indexSet.addAll(rowIndexes);
    indexSet.addAll(colIndexes);

    if (index == _chooseSudokuBox) {
      gridWellBackgroundColor = const Color.fromARGB(255, 0x70, 0xF3, 0xFF);
    } else if (indexSet.contains(_chooseSudokuBox)) {
      gridWellBackgroundColor = const Color.fromARGB(255, 0x44, 0xCE, 0xF6);
    } else {
      if (Matrix.getZone(index: index).isOdd) {
        gridWellBackgroundColor = Colors.white;
      } else {
        gridWellBackgroundColor = const Color.fromARGB(255, 0xCC, 0xCC, 0xCC);
      }
    }
    return gridWellBackgroundColor;
  }

  ///
  /// 正常网格控件
  ///
  Widget _gridInWellWidget(
      BuildContext context, int index, int num, GestureTapCallback onTap) {
    Sudoku sudoku = _state.sudoku!;
    List<int> puzzle = sudoku.puzzle;
    List<int> solution = sudoku.solution;
    List<int> record = _state.record;
    bool readOnly = true;
    bool isWrong = false;
    int num = puzzle[index];
    if (puzzle[index] == -1) {
      num = record[index];
      readOnly = false;

      if (record[index] != -1 && record[index] != solution[index]) {
        isWrong = true;
      }
    }
    return InkWell(
        highlightColor: Colors.blue,
        customBorder: Border.all(color: Colors.blue),
        onTap: onTap,
        child: Center(
          child: Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
                color: _gridInWellBgColor(index),
                border: Border.all(color: Colors.black12)),
            child: Text(
              '${num == -1 ? '' : num}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: readOnly ? FontWeight.w800 : FontWeight.normal,
                color: readOnly
                    ? Colors.blueGrey
                    : (isWrong
                        ? Colors.red
                        : const Color.fromARGB(255, 0x3B, 0x2E, 0x7E)),
              ),
            ),
          ),
        ));
  }

  ///
  /// 笔记网格控件
  ///
  Widget _markGridWidget(
      BuildContext context, int index, GestureTapCallback onTap) {
    Widget markGrid = InkWell(
      highlightColor: Colors.blue,
      customBorder: Border.all(color: Colors.blue),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _gridInWellBgColor(index),
          border: Border.all(color: Colors.black12),
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemBuilder: (BuildContext context, int index) {
            String markNum =
                '${_state.mark[index][index + 1] ? index + 1 : ""}';
            return Text(
              markNum,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _chooseSudokuBox == index
                      ? Colors.white
                      : const Color.fromARGB(255, 0x16, 0x69, 0xA9),
                  fontSize: 12),
            );
          },
        ),
      ),
    );

    return markGrid;
  }

  // well onTop function
  _wellOnTapBuilder(index) {
    // log.d("_wellOnTapBuilder build $index ...");
    return () {
      setState(() {
        _chooseSudokuBox = index;
      });
      if (_state.sudoku!.puzzle[index] != -1) {
        return;
      }
      log.d('choose position : $index');
    };
  }

  Widget _bodyWidget(BuildContext context) {
    if (_state.sudoku == null) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: const Center(
          child: Text('Sudoku Exiting...',
              style: TextStyle(color: Colors.black),
              textDirection: TextDirection.ltr),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          /// status zone
          /// life / tips / timer on here
          Container(
            height: 50,
            padding: const EdgeInsets.all(10.0),
            // color: Colors.red,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Row(
                    children: <Widget>[
                      lifePng,
                      Text(
                        " x ${_state.life}",
                        style: const TextStyle(fontSize: 18),
                      )
                    ],
                  ),
                ),
                // indicator
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: AlignmentDirectional.center,
                    child: Text(
                      "${LocalizationUtils.localizationLevelName(context, _state.level!)} - ${_state.timer} - ${LocalizationUtils.localizationGameStatus(context, _state.status)}",
                    ),
                  ),
                ),
                // tips
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      ideaPng,
                      Text(
                        " x ${_state.hint}",
                        style: const TextStyle(fontSize: 18),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          /// 9 x 9 cells sudoku puzzle board
          /// the whole sudoku game draw it here
          GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 81,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
              ),
              itemBuilder: ((BuildContext context, int index) {
                int num = -1;
                if (_state.sudoku?.puzzle.length == 81) {
                  num = _state.sudoku!.puzzle[index];
                }

                // 用户做标记
                bool isUserMark = _state.sudoku!.puzzle[index] == -1 &&
                    _state.mark[index].any((element) => element);

                if (isUserMark) {
                  return _markGridWidget(
                      context, index, _wellOnTapBuilder(index));
                }

                return _gridInWellWidget(
                    context, index, num, _wellOnTapBuilder(index));
              })),

          /// user input zone
          /// use fillZone choose number fill cells or mark notes
          /// use toolZone to pause / exit game
          Container(margin: const EdgeInsets.fromLTRB(0, 5, 0, 5)),
          _fillZone(context),
          _toolZone(context)
        ],
      ),
    );
  }

  @override
  void deactivate() {
    log.d("on deactivate");
    WidgetsBinding.instance.removeObserver(this);
    super.deactivate();
  }

  @override
  void dispose() {
    log.d("on dispose");
    _pauseTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gaming();
  }

  @override
  void didChangeDependencies() {
    log.d("didChangeDependencies");
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(SudokuGamePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    log.d("on did update widget");
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        log.d("is paused app lifecycle state");
        _pause();
        break;
      case AppLifecycleState.resumed:
        log.d("is resumed app lifecycle state");
        if (!_manualPause) {
          _gaming();
        }
        break;
      default:
        break;
    }
  }

  // 定时器
  Timer? _timer;

  void _gaming() {
    if (_state.status == SudokuGameStatus.pause) {
      log.d("on _gaming");
      _state.updateStatus(SudokuGameStatus.gaming);
      _state.persistent();
      _beginTimer();
    }
  }

  void _pause() {
    if (_state.status == SudokuGameStatus.gaming) {
      log.d("on _pause");
      _state.updateStatus(SudokuGameStatus.pause);
      _state.persistent();
      _pauseTimer();
    }
  }

  // 开始计时
  void _beginTimer() {
    log.d("timer begin");
    _timer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.status == SudokuGameStatus.gaming) {
        _state.tick();
        return;
      }
      timer.cancel();
    });
  }

  // 暂停计时
  void _pauseTimer() {
    if (_timer != null) {
      if (_timer!.isActive) {
        _timer!.cancel();
      }
    }
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    log.d("on build");
    Scaffold scaffold = Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            // ignore: void_checks
            return _aboutDialogAction(context);
          },
        )
      ]),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (didPop) {
            return;
          }
          _pause();
        },
        child: ScopedModelDescendant<SudokuState>(
          builder: (context, child, model) => _bodyWidget(context),
        ),
      ),
    );

    return scaffold;
  }
}
