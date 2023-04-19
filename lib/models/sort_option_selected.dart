import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// 被选中的排序方式
/// 歌单、歌手、专辑、音频的排序方式
///

class AudioOptionSelected with ChangeNotifier {
  /// 统一排序方式（升序和降序，默认升序）
  OrderType orderType = OrderType.ASC_OR_SMALLER;
  void changeOrderType(OrderType type) {
    orderType = type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// 不同类型，可用于排序的栏位不一样，修改时同步
  // 歌曲默认为标题排序，切换之后则需要重新排序
  SongSortType songSortType = SongSortType.TITLE;
  void changeSongSortType(SongSortType type) {
    songSortType = type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 歌单默认为PlaylistName的ASC_OR_SMALLER
  PlaylistSortType playlistSortType = PlaylistSortType.PLAYLIST;
  // 修改则是全量替换
  void changePlaylistSortType(PlaylistSortType type) {
    playlistSortType = type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 歌手默认为标题排序，切换之后则需要重新排序
  ArtistSortType artistSortType = ArtistSortType.ARTIST;
  void changeArtistSortType(ArtistSortType type) {
    artistSortType = type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 专辑默认为标题排序，切换之后则需要重新排序
  AlbumSortType albumSortType = AlbumSortType.ALBUM;
  void changeAlbumSortType(AlbumSortType type) {
    albumSortType = type;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
