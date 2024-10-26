// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart' hide Level;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:sudoku_dart/sudoku_dart.dart';

import '../state/sudoku_state.dart';
import '../util/localization_util.dart';
import 'sudoku_game.dart';

final Logger log = Logger();

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key, required this.title});

  final String title;

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

Widget _buttonWrapper(
  BuildContext context,
  Widget Function(BuildContext content) childBuilder,
) {
  return Container(
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
    width: 300,
    height: 60,
    child: childBuilder(context),
  );
}

Widget _scanButton(BuildContext context) {
  return Offstage(
      offstage: true,
      child: _buttonWrapper(
          context,
          (content) => CupertinoButton(
                color: Colors.blue,
                child: const Text("扫独解题"),
                onPressed: () {
                  log.d("scan");
                },
              )));
}

Widget _continueGameButton(BuildContext context) {
  return ScopedModelDescendant<SudokuState>(builder: (context, child, state) {
    String buttonLabel = "继续游戏";
    String continueMessage =
        "${LocalizationUtils.localizationLevelName(context, state.level ?? Level.easy)} - ${state.timer}";
    return Offstage(
        offstage: state.status != SudokuGameStatus.pause,
        child: SizedBox(
          width: 300,
          height: 80,
          child: CupertinoButton(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(buttonLabel,
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                  Text(continueMessage, style: const TextStyle(fontSize: 13))
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SudokuGamePage(title: "Sudoku"),
                  ),
                );
              }),
        ));
  });
}

void _internalSudokuGenerate(List<dynamic> args) {
  Level level = args[0];
  SendPort sendPort = args[1];

  Sudoku sudoku = Sudoku.generate(level);
  log.d("数独生成完毕");
  sendPort.send(sudoku);
}

/// 应该有一个加载数独的弹窗，在数独加载出来之后关闭。
/// 但实测数独出来后没有关闭弹窗，原因不知
Future _sudokuGenerate(BuildContext context, Level level) async {
  String sudokuGenerateText = "正在为你加载数独,请稍后...";
  // 创建一个 Completer 来控制弹窗的关闭
  Completer<void> dialogCompleter = Completer<void>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Text(sudokuGenerateText),
            )
          ],
        ),
      ),
    ),
  ).then((_) {
    debugPrint("$dialogCompleter----${dialogCompleter.isCompleted}");
    // 当 Completer 完成时关闭弹窗
    if (!dialogCompleter.isCompleted) {
      dialogCompleter.complete();
    }
  });

  ReceivePort receivePort = ReceivePort();

  Isolate isolate = await Isolate.spawn(
    _internalSudokuGenerate,
    [level, receivePort.sendPort],
  );

  var data = await receivePort.first;
  Sudoku sudoku = data;
  SudokuState state = ScopedModel.of<SudokuState>(context);
  state.initialize(sudoku: sudoku, level: level);
  state.updateStatus(SudokuGameStatus.pause);
  receivePort.close();
  isolate.kill(priority: Isolate.immediate);

  log.d("receivePort.listen done! ffffffffffffffffffffffff$receivePort");

  debugPrint("应该关闭弹窗了-----");
  // dismiss dialog
  // Navigator.pop(context);

  // 关闭弹窗
// 完成 Completer 以关闭弹窗
  dialogCompleter.complete();
}

Widget _newGameButton(BuildContext context) {
  return _buttonWrapper(
      context,
      (_) => CupertinoButton(
          color: Colors.blue,
          child: const Text(
            "新游戏",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            // cancel new game button
            Widget cancelButton = SizedBox(
                height: 60,
                width: MediaQuery.of(context).size.width,
                child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                    child: CupertinoButton(
                      // color: Colors.red,
                      child: const Text("取消"),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    )));

            // iterative difficulty build buttons
            List<Widget> buttons = [];
            for (var level in Level.values) {
              String levelName =
                  LocalizationUtils.localizationLevelName(context, level);
              buttons.add(
                SizedBox(
                  height: 60,
                  width: MediaQuery.of(context).size.width,
                  child: Container(
                    margin: const EdgeInsets.all(2.0),
                    child: CupertinoButton(
                      child: Text(
                        levelName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        log.d("begin generator Sudoku with level : $levelName");
                        // await _sudokuGenerate(context, level);

                        // 因为上面那个加载数独时显示弹窗的方法无效，所以直接这里初始化数独
                        ReceivePort receivePort = ReceivePort();

                        Isolate isolate = await Isolate.spawn(
                          _internalSudokuGenerate,
                          [level, receivePort.sendPort],
                        );

                        var data = await receivePort.first;
                        Sudoku sudoku = data;
                        SudokuState state =
                            ScopedModel.of<SudokuState>(context);
                        state.initialize(sudoku: sudoku, level: level);
                        state.updateStatus(SudokuGameStatus.pause);
                        receivePort.close();
                        isolate.kill(priority: Isolate.immediate);

                        debugPrint("-------------");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SudokuGamePage(title: "Sudoku"),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }
            buttons.add(cancelButton);

            showCupertinoModalBottomSheet(
              context: context,
              builder: (context) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Material(
                        child: SizedBox(
                            height: 300,
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: buttons))),
                  ),
                );
              },
            );
          }));
}

class _BootstrapPageState extends State<BootstrapPage> {
  @override
  Widget build(BuildContext context) {
    Widget body = Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20.0),
        child: Center(
            child: Column(
          children: <Widget>[
            // logo
            Expanded(
                flex: 1,
                child: Container(
                    alignment: Alignment.center,
                    color: Colors.white,
                    width: 280,
                    height: 280,
                    child: const Image(
                      image: AssetImage("assets/games/sodoku/image/logo.png"),
                    ))),
            Expanded(
                flex: 1,
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  // continue the game
                  _continueGameButton(context),
                  // new game
                  _newGameButton(context),
                  // scanner ?
                  _scanButton(context),
                ]))
          ],
        )));

    return ScopedModelDescendant<SudokuState>(
      builder: (context, child, model) => Scaffold(body: body),
    );
  }
}
