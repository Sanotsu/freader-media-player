// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:freader_music_player/common/global/constants.dart';
import 'package:provider/provider.dart';

import '../../../models/audio_long_press.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/service_locator.dart';
import '../widgets/build_add_to_playlist_dialog.dart';
import '../widgets/build_audio_info_dialog.dart';
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
    return WillPopScope(
      onWillPop: () async {
        // 点击appbar返回按钮或者返回键时，可以做一些操作。这里返回一个重新加载列表中的音频标识。
        // 因为在歌单删除了音频或者添加之后，直接返回不会重新加载，显示的数量没变。
        if (mounted) {
          Navigator.pop(context, {"isReload": true});
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<AudioLongPress>(
            builder: (context, alp, child) {
              // 选中的音频数量
              var tempNum = alp.selectedAudioList.length;

              return tempNum > 0
                  ? Text("选中$tempNum首", style: TextStyle(fontSize: 16.sp))
                  : Text(widget.audioListTitle);
            },
          ),
          actions: <Widget>[
            // 因为使用了consumer，在其他组件中改变了其中类的属性，这里也会识别到
            Consumer<AudioLongPress>(
              builder: (context, alp, child) {
                print(
                  "1111xxxxxxxxxxxxxxxxxxxxxxxxxxx ${alp.isAudioLongPress}  ${alp.currentTabName} ${alp.selectedAudioList.length}",
                );

                /// 如果是在播放列表中对某音频进行了长按，则在此处显示一些功能按钮
                ///   暂时有：查看信息、从当前列表移除、三个点（添加到播放列表、添加到队列(这个暂不实现)、全选等）
                /// 如果是默认显示的，应该有：排序、搜索、三个点（展开其他功能）
                return alp.isAudioLongPress
                    ? buildLongPressButtons(alp)
                    : buildDefaultButtons();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<AudioLongPress>(
                builder: (context, alp, child) {
                  print(
                      "1111LocalMusicAudioListDetail ${alp.isAudioLongPress} ");

                  /// 如果是在播放列表中对某音频进行了长按，则在此处显示一些功能按钮
                  ///   暂时有：查看信息、从当前列表移除、三个点（添加到播放列表、添加到队列(这个暂不实现)、全选等）
                  /// 如果是默认显示的，应该有：排序、搜索、三个点（展开其他功能）
                  return MusicListFutureBuilder(
                    audioListType: widget.audioListType,
                    audioListId: widget.audioListId,
                    callback: (value) => print(value),
                  );
                },
              ),
            ),
            SizedBox(
              height: 60.sp,
              width: 1.sw,
              child: const MusicPlayerMiniBar(),
            ),
          ],
        ),
      ),
    );
  }

  // 构建默认的音频列表功能按钮组件
  Widget buildDefaultButtons() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '搜索', // 长按图标会显示的文字
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This is a 搜索'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          tooltip: '排序',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This is a 排序'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildLongPressButtons(AudioLongPress alp) {
    // var alp = context.read<AudioInList>();
    // 获取查询音乐组件实例
    final audioQuery = getIt<MyAudioQuery>();
    print(
      "111111buildLongPressButtonsXXXXXXXXXXXXXXX  ${alp.isAudioLongPress} ${alp.currentTabName}  ${widget.audioListType} ${alp.selectedAudioList}",
    );

    return Row(
      children: [
        // 暂时只有在“歌单”分类时才有从歌单移除的按钮（on audio query 插件限制）
        widget.audioListType == AudioListTypes.playlist
            ? IconButton(
                icon: const Icon(Icons.remove),
                tooltip: '从列表中移除',
                onPressed: () {
                  // 长按是保存被选中的音频，直接在这里取得后进行移除
                  for (var e in alp.selectedAudioList) {
                    audioQuery.removeFromPlaylist(widget.audioListId, e.id);
                  }
                  setState(() {
                    // 单击了功能按钮之后，立马切回长按状态为否
                    alp.changeIsAudioLongPress(false);
                    alp.changeSelectedAudioList([]);
                  });
                },
              )
            : Container(),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: '添加到歌单',
          onPressed: () => buildAddToPlaylistDialog(
            context,
            alp,
            widget.audioListType,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.info),
          tooltip: '详细信息',
          onPressed: () => buildAudioInfoDialog(context, alp),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: '更多功能',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This is a 更多功能'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}
