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

class _CusVideoPlayerState extends State<CusVideoPlayer>
    with WidgetsBindingObserver {
  late FlickManager flickManager;
  bool _isFlickManagerDisposed = false;
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

    // 监听页面销毁事件
    WidgetsBinding.instance.addObserver(this);

    // 进入播放页面要隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    // 2024-10-30 看起来进入播放页应该要有状态栏，这里将状态栏文字置为白色
    // SystemChrome.setSystemUIOverlayStyle(
    //   const SystemUiOverlayStyle(
    //     statusBarColor: Colors.transparent,
    //     statusBarIconBrightness: Brightness.light, // 设置状态栏文字为白色
    //   ),
    // );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      // 页面销毁或暂停时执行清理操作
      if (!_isFlickManagerDisposed) {
        flickManager.dispose();
        _isFlickManagerDisposed = true;
      }
    }
  }

  @override
  void dispose() {
    if (!_isFlickManagerDisposed) {
      flickManager.dispose();
      _isFlickManagerDisposed = true;
    }

    // 确保在页面销毁时恢复状态栏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    // 恢复到默认的屏幕方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 退出视频播放器，重置亮度为系统亮度
    resetBrightness();

    // 移除页面销毁事件监听
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();

    // flickManager.dispose();
    // super.dispose();
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
    return PopScope(
      canPop: false,
      // 退出播放页面之前，重置为竖向，关闭全屏，返回上一页。
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        // 2024-11-02
        // 如果处在当前视频播放完毕、在下一个视频开始播放前的连续播放的间隔，此时直接点击返回按钮会报错
        // [ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: Looking up a deactivated widget's ancestor is unsafe.
        // 可能是因为 FlickAutoPlayCircularProgress 还在渲染中就退出了导致的错误
        // 处理步骤(实测三步都加上了就没有报错了，单独取消倒计时或者监听生命周期后销毁都没效果)：
        // 1、在 dispose 方法中确保 FlickManager 被正确销毁：确保在页面销毁时，FlickManager 被正确销毁，避免在页面销毁后继续渲染组件。
        // 2、使用 WidgetsBindingObserver 监听页面生命周期：通过监听页面生命周期，确保在页面销毁时执行清理操作。
        // 3、直接取消连续播放的倒计时
        flickManager.flickVideoManager?.nextVideoAutoPlayTimer?.cancel();

        // 要先退出全屏，然后在 dispose 中销毁
        if (flickManager.flickControlManager!.isFullscreen) {
          flickManager.flickControlManager?.exitFullscreen();
        }

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
        // ？？？2024-11-02 考虑上下一个视频时，根据视频方向自动切换屏幕方向？
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
        flickVideoWithControls: FlickVideoWithControls(
          // 自定义的播放器控制器
          // 2024-10-30 进入播放页面，不管是否全屏都不显示状态栏了
          controls: CusVideoPlayerControls(
            flickManager: flickManager,
            dataManager: dataManager,
            currentEntity: currentEntity,
            iconSize: 24.spMin,
            fontSize: 16.spMin,
            onEnterFullScreen: (data) {
              setState(() {
                // 更新父组件中的数据
                isCusFullscreen = data;
              });
            },
          ),
          videoFit: BoxFit.contain,
        ),
      ),
    );
  }
}
