// ignore_for_file: constant_identifier_names

// 歌单、专辑、歌手等tab层面的列表被长按的时候做通知
import 'package:flutter/widgets.dart';
import 'package:on_audio_query/on_audio_query.dart';

enum LongPressStats {
  INIT,
  YES,
  NO,
  RESET, // 预留来做tab切换时改变的状态值，然后在构建子组件时判断，避免重复多次请求数据。实际还没用到，也不知道怎么用。
}

class ListLongPress with ChangeNotifier {
  // 歌单是否被长按
  // 进一步说明:如果默认就是false，那么如何区分初始化的false和取消长按后的false？
  // 修改成int或者枚举
  LongPressStats isPlaylistLongPress = LongPressStats.INIT;
  void changeIsPlaylistLongPress(LongPressStats flag) {
    isPlaylistLongPress = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 被选中的歌单列表
  List<PlaylistModel> selectedPlaylistList = [];
  // 修改则是全量替换
  void changeSelectedPlaylists(List<PlaylistModel> newList) {
    selectedPlaylistList = newList;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 重置列表长按的状态为初始值
  void resetListLongPress() {
    isPlaylistLongPress = LongPressStats.INIT;
    selectedPlaylistList.length = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 重置音频长按的状态为初始值
  void switchTabReset() {
    isPlaylistLongPress = LongPressStats.RESET;
    selectedPlaylistList.length = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 本地音乐主页的appbar的搜索字符串(不搜索的时候，置为null，和空字串查询所有做区分)
  String? localMusicAppBarSearchInput;
  void changeLocalMusicAppBarSearchInput(String? string) {
    localMusicAppBarSearchInput = string;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
