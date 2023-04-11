// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../models/is_long_press.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/service_locator.dart';

/// 添加到指定歌单的弹窗
Future<void> buildAddToPlaylistDialog(BuildContext ctx, AudioInList alp) async {
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
                // 'Library' is empty.
                if (item.data!.isEmpty) return const Text("Nothing found!");

                // 得到查询的歌单列表
                List<PlaylistModel> playlists = item.data!;

                return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 180.sp,
                        child: ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (ctx, index) {
                            return RadioListTile(
                              title: Text(playlists[index].playlist),
                              value: playlists[index].id,
                              groupValue: selectedPlaylistId,
                              onChanged: (int? value) {
                                print(
                                  "ddddddddddddd $selectedPlaylistId  ${playlists[index].id}",
                                );

                                setState(() {
                                  print("sssssssssssssssssssssssssssss $value");
                                  selectedPlaylistId = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      Divider(
                        height: 10,
                        thickness: 2.sp,
                        indent: 2,
                        endIndent: 0,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        height: 40.sp,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: Theme.of(ctext).textTheme.labelLarge,
                          ),
                          child: const Text('创建新歌单（预留）'),
                          onPressed: () async {
                            print("点击了新建歌单按钮11111");

                            Navigator.of(ctext).pop();
                            await _displayTextInputDialog(ctext, alp);
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
                    alp.changeIsLongPress(false);
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
                setState(() {
                  alp.changeSelectedPlaylistId(selectedPlaylistId!);
                  alp.changeIsAddToList(true);
                  // 单击了添加功能按钮之后，立马切回长按状态为否，等到添加到列表完成
                  alp.changeIsLongPress(false);
                });

                Navigator.of(ctext).pop();
              },
            );
          }),
        ],
      );
    },
  );
}

_displayTextInputDialog(BuildContext context, AudioInList alp) async {
  // 获取查询音乐组件实例
  final audioQuery = getIt<MyAudioQuery>();

  print("点击了添加新歌单");
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
              decoration: const InputDecoration(hintText: "输入歌单名"),
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
                    alp.changeIsLongPress(false);
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

                  print("输入新建的歌单名称");

                  /// 这里的逻辑就比较麻烦，因为使用的on audio query组件的限制
                  /// 1 创建新歌单
                  await audioQuery.createPlaylist(playInput);

                  /// 2 查询所有歌单
                  List<PlaylistModel> list = await audioQuery.queryPlaylists();

                  /// 3 从歌单列表中找到刚刚新增的歌单
                  PlaylistModel p = list
                      .firstWhere((PlaylistModel e) => e.playlist == playInput);

                  setState(() {
                    /// 4 把被选中的音频放入歌单(通过修改provide的值)
                    alp.changeIsAddToList(true);
                    alp.changeSelectedPlaylistId(p.id);
                    alp.changeIsLongPress(false);
                    Navigator.pop(context);
                  });
                },
              );
            }),
          ],
        );
      });
}
