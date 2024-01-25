import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../common/global/constants.dart';
import '../../../models/audio_long_press.dart';
import '../../../models/list_long_press.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/service_locator.dart';

/// 添加到指定歌单的弹窗
/// 如果是tab中的“全部”歌曲，不用传listType。
/// 主要是用于在歌单tab时，从A歌单到B歌单时，因为没有原始音频id，所以逻辑与其他类型的添加稍微不同。
Future<void> buildAddToPlaylistDialog(
  BuildContext ctx,
  AudioLongPress alp,
  String listType,
) async {
  // 获取查询音乐组件实例
  final audioQuery = getIt<MyAudioQuery>();
  // 每次打开添加到歌单，都没有预设被选中的
  int? selectedPlaylistId = 0;

  return await showDialog<void>(
    context: ctx,
    builder: (BuildContext ctext) {
      return AlertDialog(
        // 需要在AlertDialog中使用StatefulBuilder，否则内部的ListView改变了状态，是不会及时更新的
        // https://stackoverflow.com/questions/54734512/radio-button-widget-not-working-inside-alertdialog-widget-in-flutter
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<List<PlaylistModel>>(
              future: audioQuery.queryPlaylists(),
              builder: (context, item) {
                // Display error, if any.
                if (item.hasError) {
                  return Text(item.error.toString());
                }
                // Waiting content.
                if (item.data == null) {
                  return const CircularProgressIndicator();
                }

                // 得到查询的歌单列表
                List<PlaylistModel> playlists = item.data!;

                return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 如果点击加入歌单但没有已经存在的歌单，则只显示创建新歌单按钮部分
                      playlists.isNotEmpty
                          ? SizedBox(
                              height: 180.sp,
                              child: ListView.builder(
                                itemCount: playlists.length,
                                itemBuilder: (ctx, index) {
                                  return RadioListTile(
                                    title: Text(playlists[index].playlist),
                                    value: playlists[index].id,
                                    groupValue: selectedPlaylistId,
                                    onChanged: (int? value) {
                                      setState(() {
                                        selectedPlaylistId = value;
                                      });
                                    },
                                  );
                                },
                              ),
                            )
                          : Container(),
                      playlists.isNotEmpty
                          ? Divider(
                              height: 10,
                              thickness: 2.sp,
                              indent: 2,
                              endIndent: 0,
                              color: Colors.grey,
                            )
                          : Container(),
                      SizedBox(
                        height: 40.sp,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: Theme.of(ctext).textTheme.labelLarge,
                          ),
                          child: const Text('创建新歌单'),
                          onPressed: () async {
                            Navigator.of(ctext).pop();
                            await _displayTextInputDialog(ctext, alp, listType);
                          },
                        ),
                      )
                    ]);
              },
            );
          },
        ),
        actions: <Widget>[
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(ctext).textTheme.labelLarge,
                ),
                child: const Text('取消'),
                onPressed: () {
                  setState(() {
                    // 单击了取消功能按钮之后，立马切回长按状态为否
                    alp.resetAudioLongPress();
                  });
                  Navigator.of(ctext).pop();
                },
              );
            },
          ),
          StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(ctext).textTheme.labelLarge,
              ),
              child: const Text('添加'),
              onPressed: () {
                // 添加被选中的音频到指定歌单
                addAudioToPlaylist(
                  audioQuery,
                  alp,
                  selectedPlaylistId ?? 0,
                  listType,
                );

                setState(() {
                  // 单击了添加功能按钮之后，立马切回长按状态为否，等到添加到列表完成
                  alp.resetAudioLongPress();
                  // 关闭弹窗
                  Navigator.of(ctext).pop();
                });
              },
            );
          }),
        ],
      );
    },
  );
}

_displayTextInputDialog(
  BuildContext context,
  AudioLongPress alp,
  String listType,
) async {
  // 获取查询音乐组件实例
  final audioQuery = getIt<MyAudioQuery>();

  var playInput = "";
  return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('创建新歌单'),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return TextField(
              onChanged: (value) {
                setState(() {
                  playInput = value;
                });
              },
              // controller: _textFieldController,
              // decoration: const InputDecoration(hintText: "输入歌单名"),
              decoration: const InputDecoration(
                enabledBorder: OutlineInputBorder(
                  /*边角*/
                  borderRadius: BorderRadius.all(
                    Radius.circular(10), //边角为30
                  ),
                  borderSide: BorderSide(
                    color: Colors.amber, //边线颜色为黄色
                    width: 1, //边线宽度为2
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                  color: Colors.green, //边框颜色为绿色
                  width: 1, //宽度为5
                )),
                labelText: "输入歌单名",
                labelStyle: TextStyle(color: Colors.amber),
                hintText: "输入歌单名",
                // 输入框前置标签
                // prefixIcon: Icon(Icons.audio_file),
              ),
              // cursorColor: cursorBg, // 光标颜色
            );
          }),
          actions: <Widget>[
            StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return MaterialButton(
                color: Colors.red,
                textColor: Colors.white,
                child: const Text('取消'),
                onPressed: () {
                  setState(() {
                    // 单击了取消功能按钮之后，立马切回长按状态为否，也取消弹窗
                    alp.changeIsAudioLongPress(LongPressStats.NO);
                    Navigator.pop(context);
                  });
                },
              );
            }),
            StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
              return MaterialButton(
                color: Colors.green,
                textColor: Colors.white,
                child: const Text('确认'),
                onPressed: () async {
                  // 新建歌单的逻辑，同时加入歌单的逻辑。

                  /// 这里的逻辑就比较麻烦，因为使用的on audio query组件的限制
                  /// 0 先查看是否有同名的歌单，如果有，直接加入即可
                  /// （不做这步，因为查询和筛选这一步始终都要做，而且新建的逻辑不清楚，可能原始库在有同名歌单时已有优化）。

                  /// 1 创建新歌单
                  await audioQuery.createPlaylist(playInput);

                  /// 2 查询所有歌单
                  List<PlaylistModel> list = await audioQuery.queryPlaylists();

                  /// 3 从歌单列表中找到刚刚新增的歌单
                  PlaylistModel p = list
                      .firstWhere((PlaylistModel e) => e.playlist == playInput);

                  /// 4 添加歌单中被选中的音频到指定另一歌单
                  addAudioToPlaylist(audioQuery, alp, p.id, listType);

                  setState(() {
                    alp.changeIsAudioLongPress(LongPressStats.NO);
                    Navigator.pop(context);
                  });
                },
              );
            }),
          ],
        );
      });
}

// 添加音频到歌单(根据来源不同，操作有一点差别:如果是从歌单到歌单，多一步查询原始音频id)
addAudioToPlaylist(
  MyAudioQuery maq,
  AudioLongPress alp,
  int playlistId,
  String listType,
) {
  if (listType != AudioListTypes.playlist) {
    // 不是从A歌单到B歌单添加音频
    for (var e in alp.selectedAudioList) {
      maq.addToPlaylist(playlistId, e.id);
    }
  } else {
    // 如果是A歌单到B歌单，选择的音频，通过名称查询到原始音频信息列表
    for (var e in alp.selectedAudioList) {
      maq.queryWithFilters(e.title, WithFiltersType.AUDIOS).then((songs) {
        // 假设同名的歌曲就一首，有多首也只取第一首放入指定歌单
        maq.addToPlaylist(playlistId, SongModel(songs[0]).id);
      });
    }
  }
}
