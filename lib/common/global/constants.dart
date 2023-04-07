class GlobalConstants {
  /// 记录登入账号、状态的字符串key
  static String loginState = "loginState";
  static String loginAccount = "loginAccount";

  /// 本地音频播放中，存放当前播放列表类型、当前播放列表编号、当前音频编号的字串
  static String currentAudioListType = "currentAudioListType";
  static String currentPlaylistId = "currentPlaylistId";
  static String currentAudioIndex = "currentAudioIndex";
}

/*
// 音频播放列表支持的类型，使用扩展可以直接比较属性值
enum AudioListType { all, playlist, artist, album }

// 使用扩展给枚举带上值（但是这里返回的值不是const的，放在例如switch cass中会报错）
extension AudioListTypeExtension on AudioListType {
  String get value {
    switch (this) {
      case AudioListType.all:
        return "all";
      case AudioListType.playlist:
        return "playlist";
      case AudioListType.artist:
        return "artist";
      case AudioListType.album:
        return "album";
      default:
        return "";
    }
  }
}
*/

// 使用抽象类模拟带值的枚举
abstract class AudioListTypes {
  static const String all = "all";
  static const String playlist = "playlist";
  static const String artist = "artist";
  static const String album = "album";
}
