// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:freader_music_player/models/list_long_press.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import 'widgets/music_list_future_builder.dart';

class LocalMusicAll extends StatefulWidget {
  const LocalMusicAll({super.key});

  @override
  State<LocalMusicAll> createState() => _LocalMusicAllState();
}

class _LocalMusicAllState extends State<LocalMusicAll> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ListLongPress>(
      builder: (context, llp, child) {
        print(
          "1111xxxxLocalMusicAllxxx  ${llp.localMusicAppBarSearchInput}",
        );

        // 如果“全部”中tab有输入搜索的条件，则在构建音频列表时带上该输入条件；否则不传
        return (llp.localMusicAppBarSearchInput != null)
            ? MusicListFutureBuilder(
                audioListType: AudioListTypes.all,
                queryInputted: llp.localMusicAppBarSearchInput,
                // 删除了这个测试的callback，从全部歌曲添加指定音频到指定歌单会不生效，原因不明。
                callback: (value) => print(value),
              )
            : MusicListFutureBuilder(
                audioListType: AudioListTypes.all,
                // 删除了这个测试的callback，从全部歌曲添加指定音频到指定歌单会不生效，原因不明。
                callback: (value) => print(value),
              );
      },
    );
  }
}
