// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';

import '../common/global/constants.dart';

/// 需要用到的统一方法放在这里吧

class MySharedPreferences {
  // 获取当前的播放列表数据
  Future<List> getCurrentAudioInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // 1 当前列表类型
    final String? calType =
        prefs.getString(GlobalConstants.currentAudioListType);
    // 如果不存在列表类型，就从“全部歌曲”开始
    var listType = calType ?? AudioListTypes.all;

    // 2 当前音频在列表中的索引
    final String? caIndex = prefs.getString(GlobalConstants.currentAudioIndex);
    // 如果不存在音频编号，就从0开始
    var audioIndex = caIndex != null ? int.parse(caIndex) : 5;

    // 3 当前播放列表编号(仅当类型是“歌单”时才需要)
    final String? cpId = prefs.getString(GlobalConstants.currentAudioListId);
    // 如果不存在音频编号，就从0开始
    var playlistId = cpId != null ? int.parse(cpId) : 0;

    print("$calType + $caIndex + $cpId");

    return [listType, audioIndex, playlistId];
  }

  /// 保存当前播放列表信息类型
  Future<void> setCurrentAudioListType(listType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GlobalConstants.currentAudioListType, listType);

    print("listType----------------$listType");
  }

  /// 保存当前播放音频编号
  Future<void> setCurrentAudioIndex(audioIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GlobalConstants.currentAudioIndex, audioIndex);
    print("audioIndex----------------$audioIndex");
  }

  /// 保存当前歌单编号
  Future<void> setCurrentAudioListId(listIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GlobalConstants.currentAudioListId, listIndex);
    print("playlistId----------------$listIndex");
  }
}
