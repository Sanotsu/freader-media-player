// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screen_brightness/screen_brightness.dart';

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

  // 2024-01-24 上下滑动屏幕调整亮度
  double _currentBrightness = 1.0;
  // 是否显示当前亮度的文字
  bool _isTextVisible = false;

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

    // 2024-01-24 获取当前系统的亮度，播放视频时也默认这个亮度，然后用户可以滑动调整
    var tempBrightness = await ScreenBrightness().current;
    setState(() {
      _currentBrightness = tempBrightness;
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
      onPopInvoked: (didPop) async {
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
                    ? buildPlayScreen()
                    : const Center(child: Text("该视频文件不存在!")),
          ),
        ),
      ),
    );
  }

  // 构建视频播放器界面，上下滑动可调节亮度
  buildPlayScreen() {
    return GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails details) {
        // 当滑动调整亮度时就显示当前亮度值
        setState(() {
          _isTextVisible = true;
        });

        // 计算滑动的百分比(这个dy根据向上或者向下已经是正数或者负数了，这个context的高度可能不存在)
        double delta = details.delta.dy / (context.size?.height ?? 360);

        // 根据滑动的百分比计算亮度的变化值。调整亮度变化速度，可根据需要自行调整
        double brightnessDelta = -delta * 0.5;

        // 更新当前的屏幕亮度值
        setState(() {
          _currentBrightness += brightnessDelta;
          // 限制亮度值在0.0到1.0之间
          _currentBrightness = _currentBrightness.clamp(0.0, 1.0);
        });

        // 修改屏幕亮度
        setBrightness(_currentBrightness);
      },
      onVerticalDragEnd: (details) {
        // 纵向滑动结束后，亮度文字就不显示了
        setState(() {
          _isTextVisible = false;
        });
      },
      child: Stack(
        children: [
          SizedBox(
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
              preferredDeviceOrientation:
                  currentEntity.orientatedSize.aspectRatio > 1
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
          ),

          // 在上下滑动跳转亮度时，也再左上角显示调整后的亮度值；1秒后自动隐藏(变透明)
          Positioned(
            top: 20,
            left: 20,
            child: AnimatedOpacity(
              opacity: _isTextVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1000),
              child: Text(
                '亮度: ${(_currentBrightness * 100).toInt()}%',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
