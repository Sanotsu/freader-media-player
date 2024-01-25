import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';

class CusDataManager {
  CusDataManager({
    required this.flickManager,
    required this.files,
    required this.currentPlaying,
  });
  // 需要播放的文件列表
  final List<File> files;
  // 当前被点击的正在播放的索引
  int currentPlaying;
  final FlickManager flickManager;

  bool hasNextVideo() => currentPlaying != files.length - 1;

  bool hasPreviousVideo() => currentPlaying != 0;

  String getVideoName() =>
      path.basenameWithoutExtension(files[currentPlaying].path);

  File getVideoFile() => (files[currentPlaying]);

  // 返回true或者false表示是否完成了跳转下一个视频；如果没有下一个视频，调用处就直接返回到列表页面
  bool skipToNextVideo([Duration? duration]) {
    if (hasNextVideo()) {
      flickManager.handleChangeVideo(
        VideoPlayerController.file(files[currentPlaying + 1]),
        videoChangeDuration: duration,
      );
      currentPlaying++;
      return true;
    } else {
      return false;
    }
  }

  skipToPreviousVideo() {
    if (hasPreviousVideo()) {
      currentPlaying--;
      flickManager.handleChangeVideo(
        VideoPlayerController.file(files[currentPlaying]),
      );
    }
  }
}
