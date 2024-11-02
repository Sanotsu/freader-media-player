import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';

import 'cus_data_manager.dart';

///
/// 2024-01-16
/// 从感官说，这里的尺寸不添加.sp，在横向或竖向展示时才是一致的；加了.sp之后，竖向播放时图标会小很多
/// 2024-01-25
/// 实测，这里调整播放器的音量，应该只是调整了应用音量，无法调整系统音量。
///   比如系统音量是0.3,而这里调整的0~1,就是这0.3*(0~1)的调节，至少不能调大音量
/// 所以添加了系统音量调节之后，就取消应用内音量调节了
/// 2024-10-31
/// 注意，这里的尺寸单位是spMin。
///   如果是之前的sp，在竖向播放控制器的图标文字大小正常，但横向时就变得非常大了
///
class CusVideoPlayerControls extends StatefulWidget {
  const CusVideoPlayerControls({
    super.key,
    this.iconSize = 25,
    this.fontSize = 12,
    this.dataManager,
    required this.currentEntity,
    required this.flickManager,
    required this.onEnterFullScreen,
  });
  final double iconSize;
  final double fontSize;
  final CusDataManager? dataManager;
  final AssetEntity currentEntity;
  final FlickManager flickManager;

  // 是否点击了全屏，给父组件返回一个标识
  final ValueChanged<bool> onEnterFullScreen;

  @override
  State<CusVideoPlayerControls> createState() => _CusVideoPlayerControlsState();
}

class _CusVideoPlayerControlsState extends State<CusVideoPlayerControls> {
  // 2024-01-25 当前系统音量(屏幕右边纵向滑动就修改这个)
  double _currentSystemVolume = 0;
  // 2024-01-24 上下滑动屏幕调整亮度
  double _currentBrightness = 1.0;
  // 是否显示当前亮度的文字
  bool _isBrightnessTextVisible = false;
  // 是否显示当前音量的文字
  bool _isVolumeTextVisible = false;
  // 2024-01-25 在纵向滑动开始时，记录滑动的x坐标，以判断是左边滑动调整亮度还是右边滑动调整音量
  double verticalDragStartX = 0;

  @override
  void initState() {
    super.initState();
    initSystemVolume();
  }

  initSystemVolume() async {
    // 调整音量时不显示系统UI
    await FlutterVolumeController.updateShowSystemUI(false);
    final volume = await FlutterVolumeController.getVolume();
    setState(() {
      _currentSystemVolume = volume ?? 0;
    });
  }

  // 退出播放页面，返回到视频列表页面
  _backToList(BuildContext context) {
    // SystemChrome.setEnabledSystemUIMode(
    //   SystemUiMode.manual,
    //   overlays: SystemUiOverlay.values,
    // );

    // 如果是全屏，退出全屏
    if (widget.flickManager.flickControlManager != null &&
        widget.flickManager.flickControlManager!.isFullscreen) {
      widget.flickManager.flickControlManager?.exitFullscreen();
    }

    // 退出前还原设备方向为竖向
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        var tempSize = context.size;

        /// 左半屏滑动逻辑，调整应用内亮度
        if (verticalDragStartX < ((tempSize?.width ?? 0.5.sh) / 2)) {
          // 当滑动调整亮度时就显示当前亮度值
          setState(() {
            _isBrightnessTextVisible = true;
          });

          // 计算滑动的百分比(这个dy根据向上或者向下已经是正数或者负数了，这个context的高度可能不存在)
          double delta = details.delta.dy / (tempSize?.height ?? 360.spMin);
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
        } else {
          /// 右半屏滑动逻辑，调整应用内系统音量

          // 当滑动调整音量时就显示当前音量值
          setState(() {
            _isVolumeTextVisible = true;
          });

          // 计算滑动的百分比(这个dy根据向上或者向下已经是正数或者负数了，这个context的高度可能不存在)
          double delta = details.delta.dy / (tempSize?.height ?? 360);
          // 根据滑动的百分比计算音量的变化值。调整音量变化速度，可根据需要自行调整
          double volumeDelta = -delta * 0.5;

          // 更新当前的系统音量
          setState(() {
            _currentSystemVolume += volumeDelta;
            // 限制音量值在0.0到1.0之间
            _currentSystemVolume = _currentSystemVolume.clamp(0.0, 1.0);
          });
          // 修改系统音量
          FlutterVolumeController.setVolume(_currentSystemVolume);
        }
      },
      // 在纵向滑动开始时，记录滑动的横坐标。如果横坐标在屏幕左半边，就控制亮度；右半边就控制音量
      onVerticalDragStart: (details) {
        setState(() {
          verticalDragStartX = details.localPosition.dx;
        });
      },
      // 纵向滑动结束后，亮度文字就不显示了
      onVerticalDragEnd: (details) {
        setState(() {
          _isBrightnessTextVisible = false;
          _isVolumeTextVisible = false;
        });
      },
      child: buildStackArea(),
    );
  }

  buildStackArea() {
    // 视频上方标题文字，根据是否全屏切换显示长度
    var titleWidth = 0.8.sw *
        (widget.currentEntity.width / (ScreenUtil().pixelRatio ?? 1) / 1.sw);

    return Stack(
      children: <Widget>[
        /// 左上角显示视频名称
        Positioned(
          left: 10.spMin,
          top: 15.spMin,
          child: FlickAutoHideChild(
            child: SizedBox(
              width: titleWidth,
              child: Text(
                widget.dataManager!.getVideoName(),
                style: TextStyle(
                  fontSize: 16.spMin,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // 2024-01-25 在上下滑动调整亮度时，也再左上角显示调整后的亮度值；1秒后自动隐藏(变透明)
        Positioned(
          top: 40.spMin, // 避免遮挡左上角的标题
          left: 20.spMin,
          child: AnimatedOpacity(
            opacity: _isBrightnessTextVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1000),
            child: Text(
              '亮度: ${(_currentBrightness * 100).toInt()}%',
              style: TextStyle(fontSize: 14.spMin, color: Colors.white),
            ),
          ),
        ),

        /// 中间的上一条/暂停继续/下一条的按钮区域
        _buildCenterControlButtonArea(context),

        /// 底部已播放时长/总时长 和 进度条区域
        _buildBottomProgressBarArea(context),

        /// 右上角的关闭按钮
        Positioned(
          right: 10.spMin,
          top: 10.spMin,
          child: FlickAutoHideChild(
            child: GestureDetector(
              onTap: () {
                _backToList(context);
                // 重置应用内调节的亮度为系统亮度
                resetBrightness();
              },
              child: Icon(Icons.cancel_outlined, size: 30.spMin),
            ),
          ),
        ),

        /// 右边中间的声音调整
        // 2024-01-25 在上下滑动调整亮度时，也在右上角显示调整后的音量值；1秒后自动隐藏(变透明)
        Positioned(
          top: 40.spMin, // 避免遮挡右上角关闭按钮
          right: 20.spMin,
          child: AnimatedOpacity(
            opacity: _isVolumeTextVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 1000),
            child: Text(
              '音量: ${(_currentSystemVolume * 100).toInt()}%',
              style: TextStyle(fontSize: 16.spMin, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // 中间的上下一个/暂停/取消连播的按钮位置
  _buildCenterControlButtonArea(BuildContext context) {
    var flickVideoManager = Provider.of<FlickVideoManager>(context);

    return FlickShowControlsAction(
      child: FlickSeekVideoAction(
        child: Center(
          child: flickVideoManager.nextVideoAutoPlayTimer != null
              // 如果是一个视频播放完了，显示连播倒计时按钮；可以立即播放下一个或者取消连播
              ? FlickAutoPlayCircularProgress(
                  colors: FlickAutoPlayTimerProgressColors(
                    backgroundColor: Colors.white30,
                    color: Colors.red,
                  ),
                  playChild: Icon(Icons.play_arrow, size: 24.spMin),
                  cancelChild: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.spMin),
                    child: Text(
                      '取消连播',
                      style: TextStyle(fontSize: 20.spMin),
                    ),
                  ),
                )
              // 如果取消连播，或者当前视频还没播完，显示上一个、暂停/继续、下一个按钮
              : FlickAutoHideChild(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(5.spMin),
                        child: GestureDetector(
                          onTap: () {
                            widget.dataManager!.skipToPreviousVideo();
                          },
                          child: Icon(
                            Icons.skip_previous,
                            color: widget.dataManager!.hasPreviousVideo()
                                ? Colors.white
                                : Colors.white38,
                            size: 35.spMin,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.spMin),
                        child: FlickPlayToggle(
                          size: 50.spMin,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.spMin),
                        child: GestureDetector(
                          onTap: () {
                            bool rst = widget.dataManager!.skipToNextVideo();
                            if (!rst) {
                              _backToList(context);
                            }
                          },
                          child: Icon(
                            Icons.skip_next,
                            color: widget.dataManager!.hasNextVideo()
                                ? Colors.white
                                : Colors.white38,
                            size: 35.spMin,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // 下方的进度条、静音按钮等其他功能按钮的位置
  _buildBottomProgressBarArea(BuildContext context) {
    return Positioned.fill(
      child: FlickAutoHideChild(
        child: Column(
          children: <Widget>[
            Expanded(child: Container()),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20.spMin,
                vertical: 10.spMin,
              ),
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // 继续或者暂停按钮
                  FlickPlayToggle(size: widget.iconSize),
                  SizedBox(width: 10.spMin),

                  // 已播放时间和总时间
                  FlickCurrentPosition(fontSize: widget.fontSize),
                  const Text(' / '),
                  FlickTotalDuration(fontSize: widget.fontSize),

                  SizedBox(width: 10.spMin),
                  // 进度条
                  Expanded(
                    child: FlickVideoProgressBar(
                      flickProgressBarSettings: FlickProgressBarSettings(
                        height: 10.spMin,
                        handleRadius: 10.spMin,
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.spMin,
                          vertical: 8.spMin,
                        ),
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white38,
                        getPlayedPaint: (
                            {double? handleRadius,
                            double? height,
                            double? playedPart,
                            double? width}) {
                          return Paint()
                            ..shader = const LinearGradient(colors: [
                              Color.fromRGBO(108, 165, 242, 1),
                              Color.fromRGBO(97, 104, 236, 1)
                            ], stops: [
                              0.0,
                              0.5
                            ]).createShader(
                              Rect.fromPoints(
                                Offset(0.sp, 0.spMin),
                                Offset(width!, 0.spMin),
                              ),
                            );
                        },
                        getHandlePaint: (
                            {double? handleRadius,
                            double? height,
                            double? playedPart,
                            double? width}) {
                          return Paint()
                            ..shader = const RadialGradient(
                              colors: [
                                Color.fromRGBO(97, 104, 236, 1),
                                Color.fromRGBO(97, 104, 236, 1),
                                Colors.white,
                              ],
                              stops: [0.0, 0.4, 0.5],
                              radius: 0.4,
                            ).createShader(
                              Rect.fromCircle(
                                center: Offset(playedPart!, height! / 2),
                                radius: handleRadius!,
                              ),
                            );
                        },
                      ),
                    ),
                  ),

                  SizedBox(width: 10.spMin),
                  // 是否静音的按钮
                  FlickSoundToggle(size: widget.iconSize),

                  SizedBox(width: 10.spMin),
                  // ???2024-01-16 进入全屏有改变方向，点击退出后无法退出全屏，也不能返回到上一个页面
                  // https://github.com/GeekyAnts/flick-video-player/issues/101

                  // 是否全屏(目前实际播放效果就跟初始化播放效果是一样的，
                  // 因为进入播放页面就有判断是横向还是竖向，然后又是Scaffold中直接的player，videoFit: BoxFit.contain,)
                  FlickFullScreenToggle(
                    size: widget.iconSize,
                    toggleFullscreen: () {
                      // 如果已经是全屏，就是退出全屏
                      if (widget.flickManager.flickControlManager != null &&
                          widget
                              .flickManager.flickControlManager!.isFullscreen) {
                        widget.flickManager.flickControlManager
                            ?.exitFullscreen();
                        widget.onEnterFullScreen(false);
                      } else {
                        widget.flickManager.flickControlManager
                            ?.enterFullscreen();
                        widget.onEnterFullScreen(true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 调整应用内的亮度
Future<void> setBrightness(double brightness) async {
  try {
    await ScreenBrightness().setApplicationScreenBrightness(brightness);
  } catch (e) {
    debugPrint(e.toString());
    throw 'Failed to set brightness';
  }
}

// 还原应用内的亮度系统亮度
Future<void> resetBrightness() async {
  try {
    await ScreenBrightness().resetApplicationScreenBrightness();
  } catch (e) {
    debugPrint(e.toString());
    throw 'Failed to reset brightness';
  }
}
