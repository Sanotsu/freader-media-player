// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

/// app的显示模式，暂时只有dark和light两种。在用户切换时，可根据状态切换

enum DisplayMode {
  DARK,
  LIGHT,
}

class ChangeDisplayMode with ChangeNotifier {
  // 歌单是否被长按
  // 进一步说明:如果默认就是false，那么如何区分初始化的false和取消长按后的false？
  // 修改成int或者枚举
  DisplayMode currentDisplayMode = DisplayMode.LIGHT;
  void changeCurrentDisplayMode(DisplayMode flag) {
    currentDisplayMode = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
