import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../common/global/constants.dart';
import '../../../models/audio_long_press.dart';
import '../../../models/list_long_press.dart';
import '../../../models/sort_option_selected.dart';
import '../widgets/build_add_to_playlist_dialog.dart';
import '../widgets/build_audio_info_dialog.dart';
import '../widgets/build_remove_playlist_or_audio_dialog.dart';
import '../widgets/build_search_text_field.dart';
import '../widgets/build_sort_options_dialog.dart';
import '../widgets/music_list_builder.dart';
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
// 是否点击了音频查询按钮(在歌单、歌手、专辑内都通用)
  bool _iSClickAudioSearch = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 避免搜索时弹出键盘，让底部的minibar位置移动到tab顶部导致溢出的问题
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            // ？？？这里需要consumer吗================
            child: Consumer2<AudioLongPress, AudioOptionSelected>(
              builder: (context, alp, aos, child) {
                return MusicListBuilder(
                  audioListType: widget.audioListType,
                  audioListId: widget.audioListId,
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
    );
  }

  /// 构建标题工具栏
  _buildAppBar() {
    return AppBar(
      title: Consumer<AudioLongPress>(
        builder: (context, alp, child) {
          /// 如果不是搜索，状态显示标题；如果是，显示搜索框
          if (!_iSClickAudioSearch) {
            // 如果有被长按选中音频，显示选中了多少首；否则显示列表名称(歌单名、歌手名、专辑名等)
            var tempNum = alp.selectedAudioList.length;

            return tempNum > 0
                ? Text("选中$tempNum首", style: TextStyle(fontSize: 16.sp))
                : Text(widget.audioListTitle);
          } else {
            return buildSearchTextField(context, alp);
          }
        },
      ),
      actions: <Widget>[
        // 因为使用了consumer，在其他组件中改变了其中类的属性，这里也会识别到
        Consumer<AudioLongPress>(
          builder: (context, alp, child) {
            /// 如果是在音频列表中对某音频进行了长按，则在顶部应用栏显示一些功能按钮
            ///   暂时有：添加到播放列表、查看信息、取消选中
            /// 如果是默认显示的，应该有：搜索、排序
            return alp.isAudioLongPress == LongPressStats.YES
                ? buildLongPressButtons(alp)
                : buildDefaultButtons();
          },
        ),
      ],
    );
  }

  // 构建默认的音频列表功能按钮组件
  Widget buildDefaultButtons() {
    return Consumer2<AudioLongPress, AudioOptionSelected>(
      builder: (context, alp, aos, child) {
        return SizedBox(
          height: 20.sp,
          child: Row(
            children: [
              // 如果没有点击搜索图标则显示搜索图标，如果点击了则改为清除图标
              !_iSClickAudioSearch
                  ? IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: '搜索音乐', // 长按图标会显示的文字
                      onPressed: () {
                        setState(() {
                          _iSClickAudioSearch = true;
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: '清空输入',
                      onPressed: () {
                        setState(() {
                          _iSClickAudioSearch = false;
                          alp.changeAudioListAppBarSearchInput(null);
                        });
                      }),
              IconButton(
                icon: const Icon(Icons.sort),
                tooltip: '排序',
                onPressed: () {
                  // 假设当前tab是1，即全部歌曲tab，这样弹窗可供选择的排序选项是音频的。
                  // 又因为无论指定的某个歌单、歌手、专辑内音频渲染内容和tab为全部歌曲是通用的，所以各自内部的音频排序也就正常的。
                  buildSortOptionsDialog(context, aos, 1);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildLongPressButtons(AudioLongPress alp) {
    return Row(
      children: [
        // 暂时只有在“歌单”分类时才有从歌单移除的按钮（on audio query 插件限制）
        widget.audioListType == AudioListTypes.playlist
            ? IconButton(
                icon: const Icon(Icons.remove),
                tooltip: '从列表中移除',
                onPressed: () => buildRemovePlaylistOrAudioDialog(
                  context,
                  alp,
                  playlistId: widget.audioListId,
                ),
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
          icon: const Icon(Icons.info_outline),
          tooltip: '详细信息',
          onPressed: () => buildAudioInfoDialog(context, alp),
        ),
        IconButton(
          icon: const Icon(Icons.cancel),
          tooltip: '取消选中',
          onPressed: () => alp.resetAudioLongPress(),
        ),
        // IconButton(
        //   icon: const Icon(Icons.more_vert),
        //   tooltip: '更多功能',
        //   onPressed: () {
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(
        //         content: Text('This is a 更多功能'),
        //         duration: Duration(seconds: 1),
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }
}
