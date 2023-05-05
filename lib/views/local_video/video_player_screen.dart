// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

/// 目前这个是单个视频的播放，可以设置单个视频播放完是暂停还是循环，但无法播放下一个。
/// 要实现，可能需要在这里播放完成之后，返回一个标识给父组件，然后父组件播放下一个；或者这里传入就是列表，进行列表中接续播放

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.file});
  final File file;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();

    initVideo();
  }

  initVideo() {
    _controller = VideoPlayerController.file(widget.file);

    // 初始化控制器，并存储Future供以后使用。
    _initializeVideoPlayerFuture = _controller.initialize();

    // 控制器设置视频循环模式
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    // 确保丢置 VideoPlayerController 以释放资源。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 在等待VideoPlayerController完成初始化时，使用FutureBuilder来显示一个加载旋钮。
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // 如果VideoPlayerController已经完成初始化，使用它提供的数据来限制视频的长宽比。

            // 这里除以3是因为layout比例就是1:3，设计宽高为360.sp × 640.sp
            double videoHeight = _controller.value.size.height / 3;
            double videoWidth = _controller.value.size.width / 3;

            print(
              "_controller.value 比例——————————————----${_controller.value.size.height}"
              "$videoHeight $videoWidth",
            );

            return Center(
              child: SizedBox(
                height: videoHeight > 640 ? 640.sp : videoHeight,
                width: videoWidth > 360 ? 360.sp : videoWidth,
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  // 使用VideoPlayer小组件来显示视频.
                  // child: VideoPlayer(_controller),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: <Widget>[
                      VideoPlayer(_controller),
                      PlayPauseOverlay(controller: _controller),
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: EdgeInsets.all(8.sp),
                        colors: const VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.green,
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            // 如果VideoPlayerController还在初始化，显示一个加载中的旋钮。
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // 将播放或暂停包在对`setState`的调用中。这确保了正确的图标被显示。
      //     setState(() {
      //       // 如果视频正在播放，暂停它。
      //       if (_controller.value.isPlaying) {
      //         _controller.pause();
      //       } else {
      //         // 如果视频暂停了，就播放它。
      //         _controller.play();
      //       }
      //     });
      //   },
      //   // 根据播放器的状态，显示正确的图标。
      //   child: Icon(
      //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
      //   ),
      // ),
    );
  }
}

class PlayPauseOverlay extends StatefulWidget {
  const PlayPauseOverlay({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  State<PlayPauseOverlay> createState() => _PlayPauseOverlayState();
}

class _PlayPauseOverlayState extends State<PlayPauseOverlay> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          // 如果视频是暂停状态，这显示暂停的按钮；如果是播放状态，则什么都不显示
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            // 将播放或暂停包在对`setState`的调用中。这确保了正确的图标被显示。
            setState(() {
              // 如果视频正在播放，暂停它。
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                // 如果视频暂停了，就播放它。
                controller.play();
              }
            });
          },
        ),
      ],
    );
  }
}
