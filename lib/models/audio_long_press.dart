import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../common/global/constants.dart';

/// 各种列表中音频列表长按的相关属性通知类
/// 用于全局获取音频是否被长按的状态，用来判断是否显示对被选中音频的功能操作按钮
/// 需要在被用到组件上层进行注入 ChangeNotifierProvider，
/// 在具体使用的地方要进行使用 Consumer 组件，或者从context中调用方法
///     var alp = context.read<AudioLongPress>();
///     alp.changeIsLongPress(true)
class AudioLongPress with ChangeNotifier {
  // 音频是否被长按
  bool isAudioLongPress = false;
  void changeIsAudioLongPress(bool flag) {
    isAudioLongPress = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 当前的tab是哪一个（可能没用）
  String currentTabName = AudioListTypes.playlist;
  void changeCurrentTabName(String name) {
    currentTabName = name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 被选中的歌单列表
  List<SongModel> selectedAudioList = [];
  // 修改则是全量替换
  void changeSelectedAudioList(List<SongModel> newList) {
    selectedAudioList = newList;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 重置音频长按的状态为初始值
  void resetAudioLongPress() {
    isAudioLongPress = false;
    currentTabName = AudioListTypes.playlist;
    selectedAudioList.length = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
