import 'package:flutter/material.dart';
import 'package:freader_music_player/models/audio_long_press.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../common/utils/tools.dart';
import 'common_small_widgets.dart';

// 显示歌单信息的弹窗
buildAudioInfoDialog(BuildContext context, AudioLongPress alp) {
  // 获取当前被选中的音频列表
  List<SongModel> list = alp.selectedAudioList;
  // 获取多选音频时所有音频的路径地址，放到list中
  var localUrlList = list
      .map((e) {
        var temp = e.data.split("/");
        temp.removeLast();
        return temp.join("/");
      })
      .toSet()
      .toList();

  return showDialog<void>(
    // // 设置为false，点击空白处弹窗不关闭，默认为true
    // // 因为在点击确认按钮关闭时，会清空被选中的音频的颜色，点击空白关闭没有做这个处理
    // // 其实不设也行，appbar的功能按钮也不隐藏即可
    // barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('属性'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: double.maxFinite,
              child: list.length > 1
                  ? ListView(
                      shrinkWrap: true,
                      children: <Widget>[
                        buildRowListTile("已选择项目数", list.length.toString()),
                        buildRowListTile("文件路径(分号分割)", localUrlList.join(";")),
                        buildRowListTile(
                          "总大小",
                          // 和js的reduce用法优点不一样，先用map取得size构建新list，再累加list的值
                          formatAudioSizeToString(
                            list
                                .map((e) => e.size)
                                .reduce((value, element) => value + element),
                          ),
                        ),
                        buildRowListTile("总文件数", list.length.toString()),
                      ],
                    )
                  : ListView(
                      shrinkWrap: true, // 自动根据内容的高度显示list的高度
                      children: <Widget>[
                        buildRowText("名称", list[0].displayName),
                        buildRowText("路径", list[0].data.toString()),
                        buildRowText(
                            "大小", formatAudioSizeToString(list[0].size)),
                        buildRowText(
                            "时长",
                            formatDurationToString(
                              Duration(milliseconds: list[0].duration!),
                            )),
                        buildRowText("歌名", list[0].title),
                        buildRowText("歌手", list[0].artist ?? "未知歌手"),
                        buildRowText("专辑", list[0].album ?? "未知专辑"),
                        buildRowText(
                            "修改时间",
                            list[0].dateModified != null
                                ? formatTimestampToString(list[0].dateModified!)
                                : ""),
                        buildRowText(
                            "获取时间",
                            list[0].dateAdded != null
                                ? formatTimestampToString(list[0].dateAdded!)
                                : ""),
                      ],
                    ),
            );
          },
        ),
        actions: <Widget>[
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return TextButton(
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                child: const Text('确认'),
                onPressed: () {
                  setState(() {
                    // 单击了取消功能按钮之后，立马切回长按状态为否,清空被选中的歌单列表，也取消弹窗
                    alp.resetAudioLongPress();
                    Navigator.pop(context);
                  });
                },
              );
            },
          ),
        ],
      );
    },
  );
}
