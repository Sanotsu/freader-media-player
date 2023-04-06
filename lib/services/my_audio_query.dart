import 'package:on_audio_query/on_audio_query.dart';

class MyAudioQuery {
// 是否有权限获取
  bool _hasPermission = false;

  // 查询本地音频组件示例
  final OnAudioQuery _query = OnAudioQuery();

  // 返回权限标志
  bool get hasPermission => _hasPermission;
  OnAudioQuery get onAudioQueryController => _query;

  // 查询本地歌曲（条件暂时就不支持自定了。这里单纯把方法抽出来，工具单例化）
  Future<List<SongModel>> querySongs() => _query.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

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
  Future<List<PlaylistModel>> queryPlaylists() => _query.queryPlaylists();

  // 创建歌单
  Future<bool> createPlaylist(String name) => _query.createPlaylist(name);

  // 删除歌单
  Future<bool> removePlaylist(int playlistId) =>
      _query.removePlaylist(playlistId);

  // 将音频添加到歌单中
  Future<bool> addToPlaylist(int playlistId, int audioId) =>
      _query.addToPlaylist(playlistId, audioId);

  // 将音频从歌单中删除
  Future<bool> removeFromPlaylist(int playlistId, int audioId) =>
      _query.removeFromPlaylist(playlistId, audioId);

  // 设置日志配置
  void setLogConfig() {
    LogConfig logConfig = LogConfig(logType: LogType.DEBUG);
    _query.setLogConfig(logConfig);
  }

  // 检查权限是否已经获取
  checkAndRequestPermissions({bool retry = false}) async {
    // The param 'retryRequest' is false, by default.
    _hasPermission = await _query.checkAndRequest(
      retryRequest: retry,
    );
  }
}
