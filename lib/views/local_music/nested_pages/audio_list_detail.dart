// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/music_list_future_builder.dart';
import '../widgets/music_player_mini_bar.dart';

/// 显示播放列表内部的歌曲，则需要传入播放列表类型、播放列表编号，额外播放列表名称用来做页面的标题
///
class LocalMusicAudioListDetail extends StatefulWidget {
  const LocalMusicAudioListDetail({
    super.key,
    required this.audioListType,
    required this.audioListId,
    required this.audioListTitle,
  });

// 传入播放列表的类型和编号用于查询，标题用于显示
  final String audioListType;
  final int audioListId;
  final String audioListTitle;

  @override
  State<LocalMusicAudioListDetail> createState() => _PlayerlistDetailState();
}

class _PlayerlistDetailState extends State<LocalMusicAudioListDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.audioListTitle),
      ),
      body: Column(children: [
        Expanded(
          child: MusicListFutureBuilder(
            audioListType: widget.audioListType,
            audioListId: widget.audioListId,
          ),
        ),
        SizedBox(
          height: 60.sp,
          width: 1.sw,
          child: const MusicPlayerMiniBar(),
        ),
      ]),
    );
  }
}
