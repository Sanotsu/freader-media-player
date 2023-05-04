// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              // 使用VideoPlayer小组件来显示视频.
              child: VideoPlayer(_controller),
            );
          } else {
            // 如果VideoPlayerController还在初始化，显示一个加载中的旋钮。
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 将播放或暂停包在对`setState`的调用中。这确保了正确的图标被显示。
          setState(() {
            // 如果视频正在播放，暂停它。
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              // 如果视频暂停了，就播放它。
              _controller.play();
            }
          });
        },
        // 根据播放器的状态，显示正确的图标。
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
