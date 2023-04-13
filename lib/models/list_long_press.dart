// 歌单、专辑、歌手等tab层面的列表被长按的时候做通知
import 'package:flutter/widgets.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ListLongPress with ChangeNotifier {
  // 歌单是否被长按
  bool isPlaylistLongPress = false;
  void changeIsPlaylistLongPress(bool flag) {
    isPlaylistLongPress = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 是否确认删除被选中的歌单
  bool isRemoveSelectedPlaylist = false;
  void changeIsRemoveSelectedPlaylist(bool flag) {
    isRemoveSelectedPlaylist = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 是否确认重命名被选中的歌单
  bool isRenamePlaylist = false;
  void changeIsRenamePlaylist(bool flag) {
    isRenamePlaylist = flag;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 当前被重命名的新歌单名称
  String newPlaylistName = "";
  void changeNewPlaylistName(String newName) {
    newPlaylistName = newName;
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
}
