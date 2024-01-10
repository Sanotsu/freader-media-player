import 'package:flutter/material.dart';

import '../../../models/audio_long_press.dart';
import '../../../models/list_long_press.dart';

/// 在本地音乐模块首页的appbar中的搜索框，或者进入指定歌单、歌手、专辑的音频列表中的appbar的搜索框
/// 前者是条件查询歌单、歌曲、歌手、专辑，后者统一为条件查询列表中的歌曲。

// 构建appbar中的条件查询框
Widget buildSearchTextField(BuildContext context, dynamic pressState) {
  var color = Theme.of(context).canvasColor;

  return TextField(
    onChanged: (String inputStr) async {
      if (pressState is AudioLongPress) {
        pressState.changeAudioListAppBarSearchInput(inputStr);
      } else if (pressState is ListLongPress) {
        pressState.changeLocalMusicAppBarSearchInput(inputStr);
      }
    },
    autofocus: true,
    cursorColor: color,
    style: TextStyle(color: color),
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      // 搜索框不显示下划线
      // border: InputBorder.none,
      // 搜索框显示白底
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: color)),
      hintText: '输入查询条件',
      hintStyle: TextStyle(color: color),
    ),
  );
}
