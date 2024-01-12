import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';

import '../common/global/constants.dart';

final box = GetStorage();

class MyGetStorage {
  // 获取当前的播放列表数据
  Future<List> getCurrentAudioInfo() async {
    // 1 当前列表类型
    // 如果不存在列表类型，就从“全部歌曲”开始
    var listType =
        box.read(GlobalConstants.currentAudioListType) ?? AudioListTypes.all;

    // 2 当前音频在列表中的索引
    // 如果不存在音频编号，就从0开始
    var audioIndex = box.read(GlobalConstants.currentAudioIndex) ?? 0;

    // 3 当前播放列表编号(仅当类型是“歌单”时才需要)
    // 如果不存在音频编号，就从0开始
    var playlistId = box.read(GlobalConstants.currentAudioListId) ?? 0;

    return [listType, audioIndex, playlistId];
  }

  /// 保存当前播放列表信息类型
  Future<void> setCurrentAudioListType(listType) async {
    await box.write(GlobalConstants.currentAudioListType, listType);
  }

  /// 保存当前播放音频编号
  Future<void> setCurrentAudioIndex(audioIndex) async {
    await box.write(GlobalConstants.currentAudioIndex, audioIndex);
  }

  /// 保存当前歌单编号
  Future<void> setCurrentAudioListId(listIndex) async {
    await box.write(GlobalConstants.currentAudioListId, listIndex);
  }

  /// 保存当前播放循环模式
  Future<void> setCurrentCycleMode(cycleMode) async {
    await box.write(GlobalConstants.currentCycleMode, cycleMode);
  }

  // 获取当前播放循环模式
  Future<LoopMode> getCurrentCycleMode() async {
    final String? ccm = box.read(GlobalConstants.currentCycleMode);

    LoopMode cycleMode;
    // 因为存入的是字符串，所以比较也是字符串，返回的是对应枚举类型
    if (ccm == LoopMode.one.toString()) {
      cycleMode = LoopMode.one;
    } else if (ccm == LoopMode.all.toString()) {
      cycleMode = LoopMode.all;
    } else {
      cycleMode = LoopMode.off;
    }
    return cycleMode;
  }

  /// 保存当前播放是否随机
  Future<void> setCurrentIsShuffleMode(isShuffleMode) async {
    await box.write(GlobalConstants.currentIsShuffleMode, isShuffleMode);
  }

  // 获取当前是否随机播放
  Future<bool> getCurrentIsShuffleMode() async {
    final String? csm = box.read(GlobalConstants.currentIsShuffleMode);

    bool isShuffle;
    // 因为存入的是字符串，所以比较也是字符串，返回的是对应枚举类型
    if (csm?.toLowerCase() == "true") {
      isShuffle = true;
    } else {
      isShuffle = false;
    }
    return isShuffle;
  }
}