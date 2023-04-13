// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/global/constants.dart';
import '../../models/audio_long_press.dart';
import 'widgets/music_list_future_builder.dart';

class LocalMusicAll extends StatefulWidget {
  const LocalMusicAll({super.key});

  @override
  State<LocalMusicAll> createState() => _LocalMusicAllState();
}

class _LocalMusicAllState extends State<LocalMusicAll> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioLongPress>(
      builder: (context, alp, child) {
        print(
            "1111xxxxLocalMusicAllxxx ${alp.isAudioLongPress} ${alp.isAddToList} ${alp.isRemoveFromList}");

        /// 如果是在播放列表中对某音频进行了长按，则在此处显示一些功能按钮
        ///   暂时有：查看信息、从当前列表移除、三个点（添加到播放列表、添加到队列(这个暂不实现)、全选等）
        /// 如果是默认显示的，应该有：排序、搜索、三个点（展开其他功能）
        return MusicListFutureBuilder(
          audioListType: AudioListTypes.all,
          // 删除了这个测试的callback，从全部歌曲添加指定音频到指定歌单会不生效，原因不明。
          callback: (value) => print(value),
        );
      },
    );
  }
}
