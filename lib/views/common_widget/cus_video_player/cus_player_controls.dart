// ignore_for_file: avoid_print

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';

import 'cus_data_manager.dart';

///
/// 2024-01-16
/// 从感官说，这里的尺寸不添加.sp，在横向或竖向展示时才是一致的；加了.sp之后，竖向播放时图标会小很多
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
  // 当前的视频音量
  double _currentVolume = 1.0;

  // 2024-01-24 上下滑动屏幕调整亮度
  double _currentBrightness = 1.0;
  // 是否显示当前亮度的文字
  bool _isTextVisible = false;

  // 2024-01-25 在纵向滑动开始时，记录滑动的x坐标，以判断是左边滑动调整亮度还是右边滑动调整音量
  double verticalDragStartX = 0;

  @override
  void initState() {
    super.initState();

    getVolume();
  }

  // 获取当前的视频音量(跟系统音量无关)
  getVolume() {
    setState(() {
      _currentVolume = widget.flickManager.flickDisplayManager?.volume ?? 1;
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

  // 修改应用内视频播放音量(不是调整系统音量，就不能加大音量了)
  Future<void> setVolume(double volume) async {
    try {
      await widget.flickManager.flickControlManager?.setVolume(volume);

      setState(() {
        _currentVolume = volume;
      });
    } catch (e) {
      debugPrint(e.toString());
      throw 'Failed to set volume';
    }
  }

  getVolumeBarHeight() {
    Size? a = widget.flickManager.flickVideoManager!.videoPlayerValue?.size;

    // 理论上是希望高度为视频高度的一半
    var b = (a?.height ?? 360) / (ScreenUtil().pixelRatio ?? 1) / 2;

    print("视频尺寸----------------$a $b ${ScreenUtil().pixelRatio}");
    return b;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        var size = context.size;

        // 左半屏滑动逻辑
        print("在纵向滑动中-----$size $verticalDragStartX $details");

        if (verticalDragStartX < ((size?.width ?? 0.5.sh) / 2)) {
          print("-----在左边");
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
        } else {
          print("-----在[右]边");
        }
      },
      onVerticalDragStart: (details) {
        print("在【onVerticalDragStart 滑动触发时-----】$details ");
        // 在横向滑动开始时，记录滑动的横坐标。如果横坐标在左半边，就控制亮度；右半边就控制音量

        setState(() {
          verticalDragStartX = details.localPosition.dx;
        });

        print(
            "在【onVerticalDragStart verticalDragStartX-----】$verticalDragStartX ");

        print("在【details.globalPosition.dx-----】${details.globalPosition.dx} ");
      },
      onVerticalDragEnd: (details) {
        // 纵向滑动结束后，亮度文字就不显示了
        setState(() {
          _isTextVisible = false;
        });
      },
      child: buildStack(),
    );
  }

  buildStack() {
    return Stack(
      children: <Widget>[
        /// 左上角显示视频名称
        Positioned(
          left: 10,
          top: 10,
          child: FlickAutoHideChild(
            child: Text(widget.dataManager!.getVideoName()),
          ),
        ),

        // 2024-01-25 在上下滑动调整亮度时，也再左上角显示调整后的亮度值；1秒后自动隐藏(变透明)
        Positioned(
          top: 30, // 避免遮挡左上角的标题
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

        /// 左边显示亮度条(在外层有滑动屏幕调整亮度了)
        // Positioned(
        //   left: 25,
        //   bottom: 50,
        //   child: FlickAutoHideChild(
        //     child: FutureBuilder<double>(
        //       future: ScreenBrightness().current,
        //       builder: (context, snapshot) {
        //         double currentBrightness = 0;
        //         if (snapshot.hasData) {
        //           currentBrightness = snapshot.data!;
        //         }
        //         return StreamBuilder<double>(
        //           stream: ScreenBrightness().onCurrentBrightnessChanged,
        //           builder: (context, snapshot) {
        //             double changedBrightness = currentBrightness;
        //             if (snapshot.hasData) {
        //               changedBrightness = snapshot.data!;
        //             }
        //             return Column(
        //               mainAxisSize: MainAxisSize.min,
        //               children: [
        //                 SizedBox(
        //                   height: 50.sp,
        //                   child: RotatedBox(
        //                     quarterTurns: 3,
        //                     child: Slider.adaptive(
        //                       value: changedBrightness,
        //                       onChanged: (value) {
        //                         setBrightness(value);
        //                       },
        //                     ),
        //                   ),
        //                 ),
        //                 const Icon(Icons.brightness_6_outlined)
        //               ],
        //             );
        //           },
        //         );
        //       },
        //     ),
        //   ),
        // ),

        /// 中间的上一条/暂停继续/下一条的按钮区域
        _buildCenterControlButtonArea(context),

        /// 底部已播放时长/总时长 和 进度条区域
        _buildBottomProgressBarArea(context),

        /// 右上角的关闭按钮
        Positioned(
          right: 10.sp,
          top: 10.sp,
          child: FlickAutoHideChild(
            child: GestureDetector(
              onTap: () {
                _backToList(context);
                // 重置应用内调节的亮度为系统亮度
                resetBrightness();
              },
              child: const Icon(Icons.cancel, size: 30),
            ),
          ),
        ),

        /// 右边中间的声音调整
        /// 2024-01-24 实测，应该只是调整了应用音量，无法调整系统音量。
        /// 比如系统音量是0.3,而这里调整的0~1,就是这0.3*(0~1)的调节，至少不能调大音量
        Positioned(
          right: 25,
          bottom: 50,
          child: FlickAutoHideChild(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: getVolumeBarHeight(),
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider.adaptive(
                      value: _currentVolume,
                      onChanged: (value) {
                        setState(() {
                          setVolume(value);
                        });
                      },
                    ),
                  ),
                ),
                const Icon(Icons.volume_down)
              ],
            ),
          ),
        ),

        /// 本来想着stack中区分左右两个区域的滑动分别控制亮度和音量，
        /// 但是后面的positioned会覆盖前面的，导致按钮就不能用了
        // 左半边区域
        // Positioned(
        //   left: 0,
        //   top: 0,
        //   bottom: 0,
        //   width: MediaQuery.of(context).size.width / 2, // 设置为屏幕宽度的一半
        //   child: GestureDetector(
        //     behavior: HitTestBehavior.translucent,
        //     onVerticalDragUpdate: (details) {
        //       // 处理音量控制逻辑

        //       print("在【左半边滑动-----】$details");
        //     },
        //     child: Container(
        //       color: Colors.green[300],
        //       alignment: Alignment.center,
        //       child: const Text(
        //         'Slide to adjust volume',
        //         style: TextStyle(fontSize: 20),
        //       ),
        //     ),
        //   ),
        // ),

        // Positioned(
        //   right: 0,
        //   top: 0,
        //   bottom: 0,
        //   width: MediaQuery.of(context).size.width / 2, // 设置为屏幕宽度的一半
        //   child: GestureDetector(
        //     onVerticalDragUpdate: (details) {
        //       // 处理音量控制逻辑

        //       print("在【右--半边滑动-----】$details");
        //     },
        //     child: Container(
        //       color: Colors.grey[300],
        //       alignment: Alignment.center,
        //       child: const Text(
        //         'Slide to adjust volume',
        //         style: TextStyle(fontSize: 20),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

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
                  playChild: const Icon(Icons.play_arrow, size: 32),
                  cancelChild: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('取消连播', style: TextStyle(fontSize: 20)),
                  ),
                )
              // 如果取消连播，或者当前视频还没播完，显示上一个、暂停/继续、下一个按钮
              : FlickAutoHideChild(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(5.sp),
                        child: GestureDetector(
                          onTap: () {
                            widget.dataManager!.skipToPreviousVideo();
                          },
                          child: Icon(
                            Icons.skip_previous,
                            color: widget.dataManager!.hasPreviousVideo()
                                ? Colors.white
                                : Colors.white38,
                            size: 35,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: FlickPlayToggle(size: 50),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
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
                            size: 35,
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

  _buildBottomProgressBarArea(BuildContext context) {
    return Positioned.fill(
      child: FlickAutoHideChild(
        child: Column(
          children: <Widget>[
            Expanded(child: Container()),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color.fromRGBO(0, 0, 0, 0.4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // 继续或者暂停按钮
                  FlickPlayToggle(size: widget.iconSize),
                  const SizedBox(width: 10),

                  // 已播放时间和总时间
                  FlickCurrentPosition(fontSize: widget.fontSize),
                  const Text(' / '),
                  FlickTotalDuration(fontSize: widget.fontSize),

                  const SizedBox(width: 10),
                  // 进度条
                  Expanded(
                    child: FlickVideoProgressBar(
                      flickProgressBarSettings: FlickProgressBarSettings(
                        height: 10,
                        handleRadius: 10,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
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
                                const Offset(0, 0),
                                Offset(width!, 0),
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

                  const SizedBox(width: 10),
                  // 是否静音的按钮
                  FlickSoundToggle(size: widget.iconSize),

                  const SizedBox(width: 10),
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
    await ScreenBrightness().setScreenBrightness(brightness);
  } catch (e) {
    debugPrint(e.toString());
    throw 'Failed to set brightness';
  }
}

// 还原应用内的亮度系统亮度
Future<void> resetBrightness() async {
  try {
    await ScreenBrightness().resetScreenBrightness();
  } catch (e) {
    debugPrint(e.toString());
    throw 'Failed to reset brightness';
  }
}
