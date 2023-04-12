import 'package:flutter/material.dart';

import '../common/global/constants.dart';

/// 各种列表中音频列表长按的相关属性通知类
/// 用于全局获取音频是否被长按的状态，用来判断是否显示对被选中音频的功能操作按钮
/// 需要在被用到组件上层进行注入 ChangeNotifierProvider，
/// 在具体使用的地方要进行使用 Consumer 组件，或者从context中调用方法
///     var alp = context.read<AudioLongPress>();
///     alp.changeIsLongPress(true)
class AudioInList with ChangeNotifier {
  // 音频是否被长按
  bool isLongPress = false;
  void changeIsLongPress(bool flag) {
    isLongPress = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 是否点击了从列表中移除被选中的音频
  bool isRemoveFromList = false;
  void changeIsRemoveFromList(bool flag) {
    isRemoveFromList = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 是否点击了添加被选中的音频到指定歌单
  bool isAddToList = false;
  void changeIsAddToList(bool flag) {
    isAddToList = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 2023-04-12 on audio query 组件的playlist（歌单）分类中id是重新递增的id，不是原始音频id
  // 而其他诸如专辑、艺术家、类型等查询到的音频id又是原始id。
  // 所以在加入歌单这个操作要分开来，如果是从歌单中添加，需要特殊表示
  bool isAddToListFromPlaylist = false;
  void changeIsAddToListFromPlaylist(bool flag) {
    isAddToListFromPlaylist = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 需要加入的歌单编号
  int selectedPlaylistId = 0;
  void changeSelectedPlaylistId(int id) {
    selectedPlaylistId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 当前的tab是哪一个
  String currentTabName = AudioListTypes.playlist;
  void changeCurrentTabName(String name) {
    currentTabName = name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
