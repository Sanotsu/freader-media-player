import 'package:flutter/widgets.dart';
import 'package:sudoku_dart/sudoku_dart.dart';

import '../state/sudoku_state.dart';

/// LocalizationUtils
class LocalizationUtils {
  static String localizationLevelName(BuildContext context, Level level) {
    switch (level) {
      case Level.easy:
        return "简单";
      case Level.medium:
        return "中等";
      case Level.hard:
        return "困难";
      case Level.expert:
        return "专家";
    }
  }

  static String localizationGameStatus(
      BuildContext context, SudokuGameStatus status) {
    switch (status) {
      case SudokuGameStatus.initialize:
        return "初始化";
      case SudokuGameStatus.gaming:
        return "进行中";
      case SudokuGameStatus.pause:
        return "暂停";
      case SudokuGameStatus.fail:
        return "失败";
      case SudokuGameStatus.success:
        return "胜利";
    }
  }
}
