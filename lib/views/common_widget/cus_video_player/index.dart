import 'dart:io';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import 'cus_data_manager.dart';
import 'cus_player_controls.dart';

class CusVideoPlayer extends StatefulWidget {
  const CusVideoPlayer({
    super.key,
    required this.entities,
    required this.index,
  });

  // 必须传入文件列表和当前播放文件的索引
  final List<AssetEntity> entities;
  final int index;

  @override
  State createState() => _CusVideoPlayerState();
}

class _CusVideoPlayerState extends State<CusVideoPlayer> {
  late FlickManager flickManager;
  late CusDataManager dataManager;

  late File? currentFile;
  late AssetEntity currentEntity;
  bool isLoading = false;

  // 默认居中显示的视频是原始的1：1分辨率，点击全屏之后就修改此标志，并全屏显示
  bool isCusFullscreen = false;

  @override
  void initState() {
    super.initState();

    initFile();
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  initFile() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    // 获取当前资源及其文件
    var entity = widget.entities[widget.index];
    var file = await entity.file;

    // 2024-01-15 需要获取所有的文件，存入文件列表
    List<File> files = [];
    for (AssetEntity element in widget.entities) {
      if (element.videoDuration != Duration.zero) {
        var temp = await element.file;
        if (temp != null) {
          files.add(temp);
        }
      }
    }

    setState(() {
      currentFile = file;
      currentEntity = entity;
    });

    if (currentFile != null) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.file(currentFile!),
        // 自动播放下一个视频的倒计时，3秒
        onVideoEnd: () {
          dataManager.skipToNextVideo(const Duration(seconds: 3));
        },
      );

      dataManager = CusDataManager(
        flickManager: flickManager,
        files: files,
        // ??? 注意，如果这里的currentFile整的有null的话，那这里传所以可能就和实际视频列表数量对不上了
        currentPlaying: widget.index,
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 进入播放页面要隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    return PopScope(
      canPop: false,
      // 退出播放页面之前，重置为竖向，关闭全屏，返回上一页。
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        // 返回之前重置方向为原始的
        // SystemChrome.setEnabledSystemUIMode(
        //   SystemUiMode.manual,
        //   overlays: SystemUiOverlay.values,
        // );

        if (flickManager.flickControlManager!.isFullscreen) {
          flickManager.flickControlManager?.exitFullscreen();
        }

        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);

        // 退出视频播放器，重置亮度为系统亮度
        resetBrightness();

        Navigator.pop(context);
      },
      child: Scaffold(
        // 默认播放页面是黑底
        body: Container(
          color: Colors.black,
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : currentFile != null
                    ? buildOnlyPlayScreen()
                    : const Center(child: Text("该视频文件不存在!")),
          ),
        ),
      ),
    );
  }

  // 构建视频播放器界面
  buildOnlyPlayScreen() {
    return SizedBox(
      // 如果不是全屏，就使用视频原始分辨率进行播放
      height: isCusFullscreen
          ? 1.sh
          : currentEntity.size.height / (ScreenUtil().pixelRatio ?? 1),
      width: isCusFullscreen
          ? 1.sw
          : currentEntity.size.width / (ScreenUtil().pixelRatio ?? 1),
      child: FlickVideoPlayer(
        flickManager: flickManager,
        // 根据视频的宽高比，显示默认是横向还是竖向播放
        preferredDeviceOrientation: currentEntity.orientatedSize.aspectRatio > 1
            ? const [
                DeviceOrientation.landscapeRight,
                DeviceOrientation.landscapeLeft
              ]
            : const [
                DeviceOrientation.portraitUp,
                DeviceOrientation.landscapeRight,
                DeviceOrientation.landscapeLeft
              ],
        // systemUIOverlay: const [],
        flickVideoWithControls: FlickVideoWithControls(
          // 自定义的播放器控制器
          controls: SafeArea(
            child: CusVideoPlayerControls(
              flickManager: flickManager,
              dataManager: dataManager,
              currentEntity: currentEntity,
              onEnterFullScreen: (data) {
                setState(() {
                  // 更新父组件中的数据
                  isCusFullscreen = data;
                });
              },
            ),
          ),
          videoFit: BoxFit.contain,
        ),
      ),
    );
  }
}
