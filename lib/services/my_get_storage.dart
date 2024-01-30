import 'package:get_storage/get_storage.dart';
import 'package:just_audio/just_audio.dart';

import '../common/global/constants.dart';
import '../views/game_center/flutter_2048/models/board.dart';

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

  /// 2024-01-25 彩蛋功能，我觉得本地视频和本地图片模块和全部资源重复太多，可以不显示
  /// 所以存一个标识来决定显示。
  /// 默认显示全部四个，但可以在每次退出弹窗中，双击content文字修改为2个(如果已经是2个就恢复到4个)
  ///
  Future<void> setBottomNavItemMun(int number) async {
    await box.write("BottomNavItemMun", number);
  }

  int getBottomNavItemMun() => box.read("BottomNavItemMun") ?? 3;

  /// 2024-01-29 2048游戏保存/获取当前棋盘状态
  Future<void> set2048BoardState(Board obj) async {
    await box.write("game2048BoardState", obj.toJson());
  }

  Board? get2048BoardState() {
    var stateStr = box.read("game2048BoardState");
    return stateStr != null
        ? Board.fromJson(Map<String, dynamic>.from(stateStr))
        : stateStr;
  }

  /// 2024-01-30 俄罗斯方块游戏保存获取历史最高分
  Future<void> setTetrisBestScore(int score) async {
    await box.write("gameTetrisBestScore", score);
  }

  int? getTetrisBestScore() => box.read("gameTetrisBestScore");
}
