import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../../common/global/constants.dart';
import '../../../common/utils/tool_widgets.dart';
import '../../../common/utils/tools.dart';
import '../../../models/audio_long_press.dart';
import '../../../models/list_long_press.dart';
import '../../../models/sort_option_selected.dart';
import '../../../services/my_audio_handler.dart';
import '../../../services/my_audio_query.dart';
import '../../../services/my_get_storage.dart';
import '../../../services/service_locator.dart';
import '../nested_pages/just_audio_music_player_detail.dart';

/// 这里是构建音频列表的显示页面
/// 需要传入播放列表类型（如果是歌单还要传入歌单编号，艺术家要传艺术家编号，专辑要传专辑编号……，好像就全部歌曲不用传）
/// 根据不同类型，调用不同查询方法

class MusicListBuilder extends StatefulWidget {
  const MusicListBuilder({
    super.key,
    required this.audioListType,
    this.audioListId,
    this.queryInputted,
  });

  final String audioListType;
  final int? audioListId;

  // 2023-04-14 如果是主页面“全部”tab的查询结果，可能把查询条件传过来。如果有，则用它；没有，才使用initFuture。
  final String? queryInputted;

  @override
  State<MusicListBuilder> createState() => _MusicListBuilderState();
}

class _MusicListBuilderState extends State<MusicListBuilder> {
  // 获取查询音乐组件实例
  final _audioQuery = getIt<MyAudioQuery>();
  // 音乐播放实例
  final _audioHandler = getIt<MyAudioHandler>();
  // 统一简单存储操作的工具类实例
  final _simpleStorage = getIt<MyGetStorage>();

  // 专门用来存放如果是指定歌单的音频列表
  // （如果这个list不为空，说明是构建显示指定歌单的音频，该插件的接口返回值audioList中没有原始音频的id，无法获取音频缩略图。
  // 需要用此list代替audioList去显示）
  List<SongModel> playlistAudioList = [];

  /// 音频多选的操作逻辑：
  /// 长按指定音频，启动播放列表功能模式
  ///     长按标志设为true，选中的音频加入指定列表，显示一些对选中音频的操作功能按钮
  ///     实现针对不同功能按钮
  /// 注意：播放列表为歌单，才有新增到其他歌单、从歌单移除等选择，其他列表因为是on audio query 直接获取到的，功能有些不一样
  ///     需要判断当前的音频列表处于哪一个tab（歌单、全部、艺术家、专辑）的详情
  ///

  // 被选中的item的索引列表
  List<SongModel> selectedIndexs = [];

  Future<List<SongModel>> initFuture(
    AudioLongPress alp, {
    AudioOptionSelected? aos,
  }) async {
    late List<dynamic> audioList;

    if (widget.audioListType == AudioListTypes.all) {
      audioList = await _audioQuery.querySongs(
        sortType: aos?.songSortType ?? SongSortType.TITLE,
        orderType: aos?.orderType ?? OrderType.ASC_OR_SMALLER,
      );
    } else if (widget.audioListType == AudioListTypes.playlist) {
      var temp = await _audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        widget.audioListId!,
        sortType: aos?.songSortType ?? SongSortType.TITLE,
        orderType: aos?.orderType ?? OrderType.ASC_OR_SMALLER,
      );

      // 如果是歌单tab进入来查询歌单中拥有的音频，因为组件接口从歌单中查询的音频结果没有原始音频id，而是编码后的编号，
      // 所以想用该音频id查询音频的例如封面图等，就取不到。
      // 所以在这里对得到的结果，用名称再查询一次，构建新的音频列表，带上原始id
      var tempList = [];
      for (SongModel e in temp) {
        var tempAl = await _audioQuery.queryWithFilters(
          e.title,
          WithFiltersType.AUDIOS,
        );
        tempList.add(tempAl[0]);
      }
      // 专门存放是指定歌单的音频列表
      playlistAudioList = tempList.toSongModel();
      // 这里不能赋值专门按名称查询后的音乐列表，是因为在从歌单移除等操作时，需要在歌单中的id而不是原始音频的id
      audioList = temp;
    } else if (widget.audioListType == AudioListTypes.artist) {
      audioList = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ARTIST_ID,
        widget.audioListId!,
        sortType: aos?.songSortType ?? SongSortType.TITLE,
        orderType: aos?.orderType ?? OrderType.ASC_OR_SMALLER,
      );
    } else if (widget.audioListType == AudioListTypes.album) {
      audioList = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        widget.audioListId!,
        sortType: aos?.songSortType ?? SongSortType.TITLE,
        orderType: aos?.orderType ?? OrderType.ASC_OR_SMALLER,
      );
    }

    // 最后就是得到了歌曲列表，统一处理
    //(知道这里的动态其实是song model，就这样转型供下面使用)
    // 注意：如果是tab页查询结果，才需要转型；否则，本身就是查询的song model类型，再转就失败了
    List<SongModel> songs =
        audioList is List<SongModel> ? audioList : audioList.toSongModel();

    // 如果是各级歌单、歌手、专辑中的条件查询，则需要在当前音频列表中过滤符合条件的
    if (alp.audioListAppBarSearchInput != null) {
      songs = songs
          .where((e) => e.title.contains(alp.audioListAppBarSearchInput!))
          .toList();
    }
    return songs;
  }

  // 在全部tab中进行条件查询
  Future<List<SongModel>> queryAudioOnAllTab() async {
    var tempList = await _audioQuery.queryWithFilters(
      widget.queryInputted!,
      WithFiltersType.AUDIOS,
    );

    return tempList is List<SongModel> ? tempList : tempList.toSongModel();
  }

  @override
  Widget build(BuildContext context) {
    AudioLongPress alp = context.watch<AudioLongPress>();
    AudioOptionSelected aos = context.watch<AudioOptionSelected>();

    // 理论上这个结果是不会用到的，它一定是下面几个if else中的某一个结果。但是不初始化这里builder是不让用的。
    Future<List<SongModel>> futureSongs = Future.value([]);

    // 如果是上层使用provide取消了长按标志，这里得清空被选中的数组(初始化时为INIT，不执行此)
    if (alp.isAudioLongPress == LongPressStats.NO) {
      selectedIndexs.length = 0;
      // 这里我以为是不能保证一定先完成了移除再获取新的歌单音频列表，但结果暂时是正确的
      setState(() {
        futureSongs = initFuture(alp, aos: aos);
      });
    }

    // 如果上层是tab的全部歌曲页面，有输入条件查询歌曲的值，这里要重新查找结果
    // 只要有传入查询条件就用这个，传空字串则查询所有
    if (widget.queryInputted != null) {
      futureSongs = queryAudioOnAllTab();
    } else {
      // 如果等于null，说明是初始化，或者关闭了查询按钮，全部歌曲要重新查询所有
      futureSongs = initFuture(alp, aos: aos);
    }

    return Center(
      child: FutureBuilder<List<SongModel>>(
          future: futureSongs,
          builder: (context, item) {
            // 如果查询出错，显示错误信息
            if (item.hasError) {
              return Text(item.error.toString());
            }
            // 如果还在加载中，显示转圈圈.
            if (item.data == null) {
              return const CircularProgressIndicator();
            }
            // 如果结果为空，显示无数据
            if (item.data!.isEmpty) {
              return const Center(child: Text("暂无歌曲"));
            }

            // 2024-10-29 直接过滤无法解析的音频(时长为空或为0的)
            List<SongModel> songs = (item.data!)
                .where((a) => a.duration != null && a.duration != 0)
                .toList();

            // 无法解析的歌曲数量
            int unsupportedNum = item.data!.length - songs.length;
            var exStr = "";
            if ((unsupportedNum > 0)) {
              exStr = "(已过滤了 $unsupportedNum 首无法解析的音频)";
            }

            return Column(
              children: [
                Text("共${songs.length}首$exStr"),
                Divider(height: 1.sp),
                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            // 音频item被长按了，设置标志为被长按，会显示一些操作按钮，且再单击音频是多选，而不是播放
                            alp.changeIsAudioLongPress(LongPressStats.YES);
                            // 长按的时候把该item索引加入被选中的索引变量中
                            selectedIndexs.add(songs[index]);
                            // 保存被选中的音频
                            alp.changeSelectedAudioList(selectedIndexs);
                          });
                        },
                        child: _buildListTileArea(songs, index, alp),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
    );
  }

  _buildListTileArea(List<SongModel> songs, int index, AudioLongPress alp) {
    // 歌手分类子标题就是专辑名，专辑分类子标题就是歌手
    SongModel song = songs[index];

    var subtext = "";
    switch (widget.audioListType) {
      case AudioListTypes.artist:
        subtext = "专辑: ${song.album}";
        break;
      default:
        subtext = song.artist ?? '未知艺术家';
    }

    // 歌曲的时长，格式化为hh:mm:ss 格式
    var songDurationStr = formatDurationToString(
      Duration(milliseconds: song.duration!),
    );

    // ??? 2023-04-27 如果是指定歌单的音频，id不是原始id，需要获得原始id以便展示缩略图
    // ??好像只有querysongs获取到的 SongModel 的id才能找到图片
    // 其他查询播放列表、艺术家的获取的音频id和querysongs的不一样，也拿不到图片
    var songId = song.id;
    if (playlistAudioList.isNotEmpty) {
      // ??? 2024-01-09 大问题，playlistAudioList中的歌曲信息和song虽然类型一样都是SongModel，
      // 但title值可能不一样，所以这个firstwhere需要一个找不到值的orelse
      songId = playlistAudioList
          .firstWhere(
            (e) => e.title == song.title,
            orElse: () => playlistAudioList[index],
          )
          .id;
    }

    return ListTile(
        selected: selectedIndexs.where((e) => e.id == song.id).isNotEmpty,
        title: Text(song.title),
        subtitle: Text(subtext),
        trailing: Text(songDurationStr),
        // 不设置默认为40，需要几乎不占位的leading则需要减少该值
        minLeadingWidth: 2.sp,
        // 这个小部件将查询/加载图像。
        leading: QueryArtworkWidget(
          controller: _audioQuery.onAudioQueryController,
          id: songId,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true, // 在生命周期内使用旧的缩略图
          // 没有缩略图时使用占位图(歌曲列表占位图和专辑、歌手、歌单等做一些区别，小圆形)
          nullArtworkWidget: CircleAvatar(
            // 设置圆形的半径
            radius: 25.sp,
            // 图像的路径
            backgroundImage: const AssetImage(placeholderImageUrl),
          ),
        ),
        onTap: () async {
          if (alp.isAudioLongPress == LongPressStats.YES) {
            setState(() {
              // 如果已经加入被选中列表，再次点击则移除
              if (selectedIndexs.where((e) => e.id == song.id).isNotEmpty) {
                selectedIndexs.removeWhere((e) => e.id == song.id);
              } else {
                selectedIndexs.add(song);
              }
              // 如果被选中的列表清空，那就假装没有点击长按用于选择音频
              if (selectedIndexs.isEmpty) {
                alp.changeIsAudioLongPress(LongPressStats.NO);
              }

              // 不管如何，点击了，就要更新被选中的歌单列表
              alp.changeSelectedAudioList(selectedIndexs);
            });
          } else {
            // 到这里就已经查询到当前“tab”页面中所有的歌曲了，可以构建播放列表和当前音频
            // 如果是条件查询，则是条件查询结果构成的歌单

            // ??? 2023-04-27 如果这个条件成立，那么是指定歌单的音频，id不是原始id，需要获得原始id以便展示缩略图
            // 存入播放列表的是包含原始音频id的列表，但和歌单中存在的音频是一样的，虽然是两个list
            // 【缺陷】: 使用的firstWhere
            // 2024-10-29 实测，这里如果点击的音频是不能解析的音频，内部的绑定音源会报错的
            try {
              if (playlistAudioList.isNotEmpty) {
                await _audioHandler.buildPlaylist(
                  playlistAudioList,
                  playlistAudioList.firstWhere(
                    (e) => e.title == song.title,
                    orElse: () => playlistAudioList[index],
                  ),
                );
              } else {
                await _audioHandler.buildPlaylist(songs, song);
              }

              await _audioHandler.refreshCurrentPlaylist();
            } catch (e) {
              if (!mounted) return;
              commonExceptionDialog(
                context,
                "提示",
                """无法解析该音频，请检查该音频格式是否正确。\n\n${song.title}""",
                msgFontSize: 15.sp,
              );

              return;
            }
            // 将播放列表信息、被点击的音频编号\播放列表编号(全部歌曲tab除外)存入持久化
            // 2024-01-09 使用get storage之后，可以有类型了，不必转为string

            // 2024-10-30  注意这里保存的当前播放音频索引index，是过滤了不可解析的音频后的列表中的位置
            // 所以在打开app重建上次播放位置的时候，播放列表也要过滤不可解析的部分
            await _simpleStorage.setCurrentAudioListType(widget.audioListType);
            await _simpleStorage.setCurrentAudioIndex(index);

            if (widget.audioListType != AudioListTypes.all) {
              await _simpleStorage.setCurrentAudioListId(widget.audioListId);
            }

            if (!mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext ctx) {
                  return const JustAudioMusicPlayer();
                },
              ),
            );
          }
        });
  }
}
