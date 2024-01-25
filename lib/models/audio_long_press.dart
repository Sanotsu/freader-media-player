import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'list_long_press.dart';

/// 各种列表中音频列表长按的相关属性通知类
/// 用于全局获取音频是否被长按的状态，用来判断是否显示对被选中音频的功能操作按钮
/// 需要在被用到组件上层进行注入 ChangeNotifierProvider，
/// 在具体使用的地方要进行使用 Consumer 组件，或者从context中调用方法
///     var alp = context.read<AudioLongPress>();
///     alp.changeIsLongPress(true)
class AudioLongPress with ChangeNotifier {
  // 音频是否被长按,默认为初始化，以区分改变长按为否时和初始化时的不同状态
  LongPressStats isAudioLongPress = LongPressStats.INIT;
  void changeIsAudioLongPress(LongPressStats flag) {
    isAudioLongPress = flag;
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
    isAudioLongPress = LongPressStats.INIT;
    selectedAudioList.length = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 重置音频长按的状态为初始值
  void switchTabReset() {
    isAudioLongPress = LongPressStats.RESET;
    selectedAudioList.length = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // xxxxx 各个(歌单、歌手、专辑)的音频列表主页的appbar的搜索字符串(不搜索的时候，置为null，和空字串查询所有做区分)
  String? audioListAppBarSearchInput;
  void changeAudioListAppBarSearchInput(String? string) {
    audioListAppBarSearchInput = string;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
