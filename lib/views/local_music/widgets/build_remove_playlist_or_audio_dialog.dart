import 'package:flutter/material.dart';
import 'package:freader_music_player/models/audio_long_press.dart';
import 'package:freader_music_player/models/list_long_press.dart';

import '../../../services/my_audio_query.dart';
import '../../../services/service_locator.dart';

/// 在歌单长按点击删除，弹窗移除选中歌单的弹窗；在指定歌单的音频列表长按点击删除，弹窗移除选中音频的弹窗。

// 显示删除歌单/音频的确认弹窗
buildRemovePlaylistOrAudioDialog(BuildContext context, dynamic pressState,
    {int? playlistId}) {
  // 获取查询音乐组件实例
  final audioQuery = getIt<MyAudioQuery>();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text((pressState is ListLongPress) ? '移除歌单' : '从歌单移除音频'),
        content: Text(
          '这仅会移除被选中的${(pressState is ListLongPress) ? '歌单' : '音频'}，而不是删除本地音频文件。',
        ),
        actions: <Widget>[
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('取消'),
                  onPressed: () {
                    setState(() {
                      // 单击了取消功能按钮之后，立马切回长按状态为否，清空被选中的歌单/音频列表,也取消弹窗
                      if (pressState is ListLongPress) {
                        pressState.resetListLongPress();
                      } else if (pressState is AudioLongPress) {
                        pressState.resetAudioLongPress();
                      }
                      Navigator.pop(context);
                    });
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('确认'),
                  onPressed: () {
                    setState(() {
                      // 点击确认按钮之后，如果是删除选中歌单，则移除歌单，重置状态；如果是删除歌单中音频，也移除音频，重置状态
                      if (pressState is ListLongPress) {
                        for (var playlist in pressState.selectedPlaylistList) {
                          audioQuery.removePlaylist(playlist.id);
                        }
                        pressState.resetListLongPress();
                      } else if (pressState is AudioLongPress) {
                        for (var e in pressState.selectedAudioList) {
                          // 注意，如果是移除歌单中选中音频，那么使用此弹窗时，一定要传
                          audioQuery.removeFromPlaylist(playlistId!, e.id);
                        }
                        pressState.resetAudioLongPress();
                      }

                      Navigator.pop(context);
                    });
                  },
                )
              ],
            );
          }),
        ],
      );
    },
  );
}
