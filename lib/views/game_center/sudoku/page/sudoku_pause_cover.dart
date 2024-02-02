import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../state/sudoku_state.dart';
import '../util/localization_util.dart';

class SudokuPauseCoverPage extends StatefulWidget {
  const SudokuPauseCoverPage({super.key});

  @override
  State<SudokuPauseCoverPage> createState() => _SudokuPauseCoverPageState();
}

class _SudokuPauseCoverPageState extends State<SudokuPauseCoverPage> {
  SudokuState get _state => ScopedModel.of<SudokuState>(context);

  @override
  Widget build(BuildContext context) {
    TextStyle pageTextStyle = const TextStyle(color: Colors.white);

    // define i18n begin
    const String levelText = "难度";
    const String pauseGameText = "游戏暂停";
    const String elapsedTimeText = "耗时";
    const String continueGameContentText = "双击屏幕继续游戏";
    // define i18n end
    Widget titleView = const Align(
      child: Text(pauseGameText, style: TextStyle(fontSize: 26)),
    );
    Widget bodyView = Align(
        child: Column(children: [
      Expanded(flex: 3, child: titleView),
      Expanded(
          flex: 5,
          child: Column(children: [
            Text(
              "$levelText [${LocalizationUtils.localizationLevelName(context, _state.level!)}] $elapsedTimeText : ${_state.timer}",
            )
          ])),
      const Expanded(
        flex: 1,
        child: Align(
            alignment: Alignment.center, child: Text(continueGameContentText)),
      )
    ]));

    onDoubleTap() {
      log.d("double click : leave this stack");
      Navigator.pop(context);
    }

    onTap() {
      log.d("single click , do nothing");
    }

    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.98),
        body: DefaultTextStyle(style: pageTextStyle, child: bodyView),
      ),
    );
  }
}
