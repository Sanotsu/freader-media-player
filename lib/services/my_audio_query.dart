// ignore_for_file: avoid_print

import 'package:on_audio_query/on_audio_query.dart';

class MyAudioQuery {
// 是否有权限获取
  bool _hasPermission = false;

  // 查询本地音频组件示例
  final OnAudioQuery _query = OnAudioQuery();

  // 返回权限标志
  bool get hasPermission => _hasPermission;
  OnAudioQuery get onAudioQueryController => _query;

// （原本在构造函数中执行初始化 存储授权，现在在获得授权后在app处初始化）
  MyAudioQuery() {
    // setLogConfig();
  }

  // 查询本地歌曲（条件暂时就不支持自定了。这里单纯把方法抽出来，工具单例化）
  Future<List<SongModel>> querySongs({
    SongSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
    bool? ignoreCase,
    String? path,
  }) =>
      _query.querySongs(
        sortType: sortType,
        orderType: orderType,
        uriType: uriType,
        ignoreCase: ignoreCase,
        path: path,
      );

  // 查询本地歌曲（可以自定义条件，尽量少用）
  Future<List<SongModel>> querySongsByConditions({
    SongSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
    bool? ignoreCase,
    String? path,
  }) async {
    return _query.querySongs(
      sortType: sortType,
      orderType: orderType,
      uriType: uriType,
      ignoreCase: ignoreCase,
      path: path,
    );
  }

  // 过滤查询
  // 返回是动态类型，因为查询的结果可能是音频列表、专辑列表、歌单列表等等，使用的是转为指定类型
  Future<List<dynamic>> queryWithFilters(
    String argsVal,
    WithFiltersType withType, {
    dynamic args,
  }) async {
    return _query.queryWithFilters(
      argsVal, // 查询的关键字
      withType, // 查询的内容（音频、歌单、专辑。。。）
      args: args ?? _getArgs(withType), // 关键字对应的栏位
    );
  }

  dynamic _getArgs(
    WithFiltersType withType,
  ) {
    switch (withType) {
      case WithFiltersType.AUDIOS:
        return AudiosArgs.TITLE;
      case WithFiltersType.ALBUMS:
        return AlbumsArgs.ALBUM;
      case WithFiltersType.PLAYLISTS:
        return PlaylistsArgs.PLAYLIST;
      case WithFiltersType.ARTISTS:
        return ArtistsArgs.ARTIST;
      case WithFiltersType.GENRES:
        return GenresArgs.GENRE;
    }
  }

  // 从哪里（例如歌单、专辑、艺术家枚举值等）查询歌曲，需要参看原方法的属性
  Future<List<SongModel>> queryAudiosFrom(
    AudiosFromType type,
    Object where, {
    SongSortType? sortType,
    OrderType? orderType,
    bool? ignoreCase,
  }) =>
      _query.queryAudiosFrom(
        type,
        where,
        sortType: sortType,
        orderType: orderType,
        ignoreCase: ignoreCase,
      );

  // 查询歌单
  Future<List<PlaylistModel>> queryPlaylists({
    PlaylistSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
    bool? ignoreCase,
  }) =>
      _query.queryPlaylists(
        sortType: sortType,
        orderType: orderType,
        uriType: uriType,
        ignoreCase: ignoreCase,
      );

  Future<DeviceModel> queryDeviceInfo() => _query.queryDeviceInfo();

  // 创建歌单
  Future<bool> createPlaylist(String name) => _query.createPlaylist(name);

  // 删除歌单
  Future<bool> removePlaylist(int playlistId) =>
      _query.removePlaylist(playlistId);

  // 重命名歌单
  Future<bool> renamePlaylist(int playlistId, String newName) =>
      _query.renamePlaylist(playlistId, newName);

  // 将音频添加到歌单中
  Future<bool> addToPlaylist(int playlistId, int audioId) =>
      _query.addToPlaylist(playlistId, audioId);

  // 将音频从歌单中删除
  Future<bool> removeFromPlaylist(int playlistId, int audioId) =>
      _query.removeFromPlaylist(playlistId, audioId);

  // 查询艺术家分类列表
  Future<List<ArtistModel>> queryArtists({
    ArtistSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
    bool? ignoreCase,
  }) =>
      _query.queryArtists(
        sortType: sortType,
        orderType: orderType,
        uriType: uriType,
        ignoreCase: ignoreCase,
      );

  // 查询专辑分类列表
  Future<List<AlbumModel>> queryAlbums({
    AlbumSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
    bool? ignoreCase,
  }) =>
      _query.queryAlbums(
        sortType: sortType,
        orderType: orderType,
        uriType: uriType,
        ignoreCase: ignoreCase,
      );

  // 设置日志配置
  void setLogConfig() {
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _query.setLogConfig(logConfig);
  }

  // 检查权限是否已经获取
  checkAndRequestPermissions({bool retry = false}) async {
    // The param 'retryRequest' is false, by default.

    print("进入了检查权限的函数");

    _hasPermission = await _query.checkAndRequest(
      retryRequest: retry,
    );
  }
}
