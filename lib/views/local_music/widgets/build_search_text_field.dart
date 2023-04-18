import 'package:flutter/material.dart';
import 'package:freader_music_player/models/audio_long_press.dart';

import '../../../models/list_long_press.dart';

/// 在本地音乐模块首页的appbar中的搜索框，或者进入指定歌单、歌手、专辑的音频列表中的appbar的搜索框
/// 前者是条件查询歌单、歌曲、歌手、专辑，后者统一为条件查询列表中的歌曲。

// 构建appbar中的条件查询框
Widget buildSearchTextField(dynamic pressState) {
  return TextField(
    onChanged: (String inputStr) async {
      if (pressState is AudioLongPress) {
        pressState.changeAudioListAppBarSearchInput(inputStr);
      } else if (pressState is ListLongPress) {
        pressState.changeLocalMusicAppBarSearchInput(inputStr);
      }
    },
    autofocus: true,
    cursorColor: Colors.white,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 20,
    ),
    textInputAction: TextInputAction.search,
    decoration: const InputDecoration(
      enabledBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      hintText: 'Search',
      hintStyle: TextStyle(
        color: Colors.white60,
        fontSize: 20,
      ),
    ),
  );
}
